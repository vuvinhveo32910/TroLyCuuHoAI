"""Extractive RAG: the model proposes document IDs, never new clinical instructions."""
from collections import OrderedDict
import hashlib
import json
import logging
import re
import threading
from urllib.parse import quote

from knowledge_search import search_documents, topic_links, demo_reference_order
from sqlite_store import StoreError
from query_understanding import local_intent, understanding_prompt, validate_understanding
from reference_relevance import eligible_references, reference_scope, is_wound_care_question


def selection_prompt(candidates,titles_only=False):
    keys=('id','title') if titles_only else ('id','title','summary')
    return json.dumps({'documents':[{k:entry[k] for k in keys} for entry in candidates]},ensure_ascii=False)


def validate_selection(raw, allowed_ids):
    raw = raw.strip()
    fenced = re.fullmatch(r'```(?:json)?\s*(.*?)\s*```',raw,re.S)
    if fenced:raw=fenced.group(1)
    value=json.loads(raw)
    if not isinstance(value,dict) or set(value)!={'entry_ids','needs_clarification'}:
        raise ValueError('Unexpected selection fields')
    ids=value['entry_ids']
    if (type(value['needs_clarification']) is not bool or not isinstance(ids,list) or len(ids)>2
            or any(type(identifier) is not int or identifier not in allowed_ids for identifier in ids)
            or len(set(ids))!=len(ids) or (not ids and not value['needs_clarification'])):
        raise ValueError('Invalid document selection')
    return value


class GroundedChat:
    def __init__(self,store,runner):
        self.store,self.runner=store,runner
        self.cache=OrderedDict()
        self.intent_cache=OrderedDict()
        self.lock=threading.Lock()

    @staticmethod
    def guides(entries):
        return [{'id':entry['id'],'title':entry['title'],'summary':entry['summary'],
                 'url':'/knowledge?id='+str(entry['id']),
                 'publication':entry.get('publication',{})} for entry in entries]

    @staticmethod
    def base():
        return {'sources':[],'truncated':False,'generated_tokens':0,'generation_seconds':0}

    def missing(self,query,published,groups):
        topics=topic_links(groups,query,published)
        names=[topic['name'] for topic in topics if topic['recognized']]
        intro='Từ bạn nhập gợi ý chủ đề tài liệu: '+', '.join(names)+'. ' if names else ''
        if not published:
            return dict(self.base(),route='no_reference',unavailable_reason='empty_catalog',suggested_groups=topics,
                        answer=intro+'Hiện kho chưa có tài liệu được duyệt chuyên môn để tra cứu. Bạn không cần nhập đúng tên tài liệu.')
        return dict(self.base(),route='clarify',unavailable_reason='no_match',suggested_groups=topics,
                    answer=intro+'Bạn muốn tra tài liệu về trầy xước, vết cắt, bỏng hay bầm tím? Hãy mô tả rõ hơn hoặc chọn nhóm tài liệu. Chưa xác định được tài liệu phù hợp nên AI chưa đưa ra hướng dẫn.')

    def fresh(self,entries):
        # Recheck after inference; an approval may be retired while the GPU is busy.
        details=[self.store.detail(entry['id'],published=True) for entry in entries]
        if any(detail['version']!=entry['version'] for detail,entry in zip(details,entries)):
            raise StoreError('Phiên bản nguồn đã thay đổi.',409)
        return details

    def clarify_intent(self, query, interpretation=None, reason='query_ambiguous'):
        interpretation = interpretation or {}
        return dict(self.base(), route='clarify', unavailable_reason=reason,
                    answer=interpretation.get('answer', 'Chưa rõ ý câu hỏi. Bạn có thể viết lại, nói rõ điều gì đã xảy ra và vị trí đang bị ảnh hưởng không?'),
                    guides=[], citations=[], query_interpretation={
                        'intent': 'unclear', 'method': 'rules',
                        'original_query': query, 'suggested_query': interpretation.get('suggested_query', '')})

    def no_relevant_source(self, query):
        return dict(self.base(), route='no_reference', unavailable_reason='no_match',
                    answer='Kho hiện chưa có nguồn phù hợp với câu hỏi này.',
                    guides=[], citations=[], suggested_groups=[],
                    query_interpretation={'intent':'out_of_catalog', 'method':'relevance_check',
                                          'original_query':query, 'search_query':''})

    def interpret(self, query, published):
        candidates = published[:20]
        key = hashlib.sha256(json.dumps([query, candidates], ensure_ascii=False, sort_keys=True).encode()).hexdigest()
        with self.lock:
            cached = self.intent_cache.get(key)
            if cached:
                self.intent_cache.move_to_end(key)
                return cached
        if getattr(self.runner, 'state', 'not_loaded') != 'ready':
            return None
        generated = self.runner.answer(query, [], understanding_prompt(candidates), 'query_understanding')
        if generated.get('truncated'):
            raise ValueError('Truncated interpretation')
        try:
            result = validate_understanding(generated['answer'], {entry['id'] for entry in candidates})
        except (ValueError, TypeError) as exc:
            # Diagnostics contain schema names/types, not the user's question or
            # a generated clinical answer.
            try:
                shape = json.loads(generated['answer'])
                shape = {k:type(v).__name__ for k,v in shape.items()} if isinstance(shape,dict) else type(shape).__name__
            except (ValueError, TypeError):
                shape = 'not_json'
            logging.getLogger(__name__).warning('Interpretation schema rejected: %s; shape=%s', str(exc), shape)
            raise
        result = dict(result, metrics={name: generated.get(name, 0) for name in ('generation_seconds', 'generated_tokens')})
        with self.lock:
            self.intent_cache[key] = result
            while len(self.intent_cache) > 32:
                self.intent_cache.popitem(last=False)
        return result

    def render(self,details,route,reason='',metrics=None):
        demo=any(detail.get('publication',{}).get('kind')=='source_reviewed_demo' for detail in details)
        lines=[('Nội dung tham khảo cho bản thử nghiệm đồ án: đã được AI đối chiếu nguồn, chưa duyệt chuyên môn. '
                'Thông tin được lấy nguyên văn từ SQLite. Đọc điều kiện áp dụng và cảnh báo; kết quả tra cứu chưa xác nhận hướng dẫn phù hợp với tình trạng của bạn.')
               if demo else 'Thông tin dưới đây lấy nguyên văn từ tài liệu đã duyệt. Đọc điều kiện áp dụng và cảnh báo; kết quả này chưa xác nhận hướng dẫn phù hợp với tình trạng của bạn.']
        citations=[]
        for detail in details:
            lines.extend(['','Tài liệu: '+detail['title'],detail['summary'],
                          'Điều kiện áp dụng: '+detail['applicability'],
                          'Trường hợp không áp dụng: '+detail['exclusions'],'Cảnh báo:'])
            for warning in detail['warnings']:
                lines.append('• '+warning['description']+' '+warning['action'])
            lines.append('Các bước theo tài liệu:')
            for step in detail['steps']:lines.append(str(step['step_number'])+'. '+step['instruction'])
            for source in detail['citations']:
                citations.append({'entry_id':detail['id'],'version':detail['version'],'title':source['source_title'],
                                  'pages':str(source['pdf_page_start'])+'–'+str(source['pdf_page_end']),
                                  'pdf_url':'/api/source/'+quote(source['file_id'],safe='')+'#page='+str(source['pdf_page_start'])})
        result=dict(self.base(),answer='\n'.join(lines),route=route,guides=self.guides(details),citations=citations,
                    evidence_mode='extractive',fallback_reason=reason,
                    source_review_label='Đã đối chiếu nguồn — chưa duyệt chuyên môn' if demo else 'Đã duyệt chuyên môn')
        if metrics:result.update(metrics)
        return result

    def extract_sources(self, query):
        """Read eligible published references for an explicit topic, without inference."""
        interpretation = local_intent(query)
        if interpretation['intent'] != 'first_aid':
            topics, _, _ = reference_scope(query)
            if (interpretation['intent'] in {'other', 'unclear'}
                    or interpretation.get('reason') == 'ambiguous_word'
                    or not (topics and is_wound_care_question(query))):
                return self.no_relevant_source(query)
        if not self.store:
            return self.missing(query, [], [])
        published = self.store.list_entries(published=True)
        eligible = eligible_references(published, query)
        matches = search_documents(eligible, query)
        if not matches:
            return self.no_relevant_source(query)
        ordered = demo_reference_order(matches, query)
        try:
            return self.render(self.fresh(ordered[:2]), 'source_grounded')
        except StoreError:
            return dict(self.base(), route='clarify', unavailable_reason='source_changed',
                        answer='Tài liệu vừa thay đổi hoặc ngừng sử dụng. Hãy tìm lại nguồn trước khi áp dụng hướng dẫn.',
                        citations=[], guides=[])

    def answer(self,query,mode='grounded',guide_id=None):
        interpretation = local_intent(query)
        if interpretation['intent'] == 'unclear':
            return self.clarify_intent(query, interpretation)
        if interpretation['intent'] == 'other':
            return dict(self.base(), route='no_reference', unavailable_reason='no_match', guides=[],
                        answer='Câu hỏi này không yêu cầu hướng dẫn sơ cứu trong kho.',
                        query_interpretation={'intent': 'other', 'method': 'rules', 'original_query': query,
                                              'topic_hint': interpretation.get('topic_hint','nonmedical')})
        if guide_id is not None:
            interpretation={'intent':'first_aid'}
        if not self.store:
            return self.missing(query,[],[])
        groups=self.store.summary()['injury_types']
        published=self.store.list_entries(published=True)
        eligible=eligible_references(published,query)
        if guide_id is not None:
            if type(guide_id) is not int or guide_id<1:raise StoreError('Mã tài liệu không hợp lệ.')
            # A caller cannot force a draft into the prompt through an ID.
            chosen=self.store.detail(guide_id,published=True)
            if chosen['id'] not in {entry['id'] for entry in eligible}:
                return self.no_relevant_source(query)
            matches=[chosen]
        else:
            matches=search_documents(eligible,query)
        if not published:return self.missing(query,published,groups)
        # Without a candidate supported by the original question, selecting a
        # document cannot help. Let the answering model ask symptom questions;
        # keep genuinely ambiguous homonyms in the clarification path.
        if not eligible and interpretation.get('reason')!='ambiguous_word':
            return self.no_relevant_source(query)
        if mode=='lookup':
            if interpretation.get('reason') == 'ambiguous_word':
                return self.clarify_intent(query)
            if not matches:return self.missing(query,published,groups)
            return dict(self.base(),route='reference_list',guides=self.guides(matches[:6]),
                        answer='Tìm thấy tài liệu tham khảo có liên quan. Mở tài liệu để đọc trạng thái duyệt, điều kiện áp dụng, phạm vi loại trừ và cảnh báo; kết quả tra cứu chưa xác định hướng dẫn nào phù hợp với tình trạng của bạn.')

        # A known topic can show conditional source information for the academic
        # demo immediately, without waiting for an AI document selector.
        if interpretation['intent']=='first_aid' and matches and all(entry.get('publication',{}).get('kind')=='source_reviewed_demo' for entry in matches[:2]):
            ordered=matches if guide_id is not None else demo_reference_order(matches,query)
            try:return self.render(self.fresh(ordered[:2]),'source_grounded')
            except StoreError:
                return dict(self.base(),route='no_reference',unavailable_reason='source_changed',
                            answer='Nội dung hoặc nguồn tham khảo vừa thay đổi. Hãy tìm lại tài liệu.')

        if interpretation['intent'] == 'unknown':
            try:
                understood = self.interpret(query, eligible)
            except Exception as exc:
                logging.getLogger(__name__).warning('Query interpretation rejected (%s: %s).', type(exc).__name__, str(exc))
                return self.clarify_intent(query, reason='interpretation_unavailable')
            if understood is None:
                # Do not trust a lexical hit for an ambiguous homonym while AI is unavailable.
                if matches or interpretation.get('reason') == 'ambiguous_word':
                    return self.clarify_intent(query, reason='interpretation_unavailable')
                return self.missing(query, published, groups)
            meta = {'intent': understood['intent'], 'method': 'ai', 'original_query': query,
                    'search_query': understood['search_query']}
            if (understood['intent'] == 'first_aid' and not understood['needs_clarification']
                    and not understood['entry_ids'] and understood['search_query'].strip()):
                semantic_matches = search_documents(eligible, understood['search_query'])
                understood = dict(understood, entry_ids=[entry['id'] for entry in semantic_matches[:2]])
            if understood['intent'] == 'other' or (understood['intent']=='first_aid'
                    and not understood['entry_ids'] and not understood['needs_clarification']):
                return dict(self.base(), route='no_reference', unavailable_reason='no_match', guides=[],
                            answer='Chưa tìm thấy nguồn phù hợp với ý câu hỏi.', query_interpretation=meta,
                            **understood['metrics'])
            if understood['intent'] == 'unclear' or not understood['entry_ids']:
                result = self.clarify_intent(query)
                result.update(query_interpretation=meta, **understood['metrics'])
                return result
            # A semantic paraphrase or spelling correction must be confirmed by
            # choosing a document; interpretation never establishes a diagnosis.
            chosen = [entry for entry in eligible if entry['id'] in understood['entry_ids']]
            try:
                self.fresh(chosen)
            except StoreError:
                return dict(self.base(), route='no_reference', unavailable_reason='source_changed',
                            answer='Nguồn vừa thay đổi. Hãy gửi lại câu hỏi.')
            return dict(self.base(), route='clarify', unavailable_reason='query_ambiguous',
                        answer='AI nhận diện câu hỏi có thể liên quan đến tài liệu bên dưới. Hãy xác nhận tài liệu phù hợp hoặc viết lại câu hỏi; hệ thống chưa kết luận bạn bị loại tổn thương này.',
                        guides=self.guides(chosen), citations=[], query_interpretation=meta,
                        **understood['metrics'])

        # Metadata is sufficient for document selection. Full instructions and every
        # warning are rendered from SQLite, outside model output/token truncation.
        candidates=matches[:3] if matches else eligible[:20]
        context=selection_prompt(candidates,titles_only=not matches)
        key=hashlib.sha256(json.dumps([query,guide_id,candidates],ensure_ascii=False,sort_keys=True).encode()).hexdigest()
        selected=None;metrics=None;route='model_grounded';reason=''
        with self.lock:
            cached=self.cache.get(key)
            if cached:
                selected,metrics=cached
                self.cache.move_to_end(key)
                route='cache'
        if selected is None and getattr(self.runner,'state','not_loaded')=='ready' and len(context)<=5000:
            try:
                generated=self.runner.answer(query,[],context,'reference_selection')
                if generated.get('truncated'):raise ValueError('Truncated selection')
                selected=validate_selection(generated['answer'],{entry['id'] for entry in candidates})
                metrics={name:generated.get(name,0) for name in ('generation_seconds','generated_tokens')}
            except Exception:
                reason='selection_unavailable'
        elif selected is None:
            reason='model_not_ready' if getattr(self.runner,'state','not_loaded')!='ready' else 'context_too_long'

        if selected is None:
            if not matches:return self.missing(query,published,groups)
            selected={'entry_ids':[entry['id'] for entry in matches[:2]],'needs_clarification':False}
            route='source_grounded'

        by_id={entry['id']:entry for entry in candidates}
        chosen=[by_id[identifier] for identifier in selected['entry_ids']]
        if not chosen and not matches:
            return self.missing(query,published,groups)
        if selected['needs_clarification'] or (not matches and guide_id is None):
            # An AI-only topic match requires the user to choose a document. This is
            # document confirmation, never an attestation of clinical applicability.
            suggestions=chosen if chosen else candidates[:6]
            try:self.fresh(suggestions)
            except StoreError:return self.missing(query,self.store.list_entries(published=True),groups)
            result=self.missing(query,published,groups)
            result.update(answer='AI chưa xác định đủ rõ tài liệu bạn muốn hỏi. Bạn muốn tham khảo tài liệu nào bên dưới? Nếu các mục chưa đúng, hãy mô tả rõ hơn. Lựa chọn tài liệu không xác nhận loại hay mức độ tổn thương.',
                          guides=self.guides(suggestions))
            if metrics:result.update(metrics)
            return result
        try:
            details=self.fresh(chosen)
        except StoreError:
            with self.lock:self.cache.pop(key,None)
            return dict(self.base(),route='no_reference',unavailable_reason='source_changed',
                        answer='Tài liệu vừa thay đổi trạng thái hoặc ngừng sử dụng. Hãy tìm lại; AI không tiếp tục trả lời bằng phiên bản này.')
        if route=='model_grounded' and not reason:
            with self.lock:
                self.cache[key]=(selected,metrics)
                while len(self.cache)>32:self.cache.popitem(last=False)
        if route=='cache':metrics=dict(metrics or {},original_route='model_grounded')
        return self.render(details,route,reason,metrics)
