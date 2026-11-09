"""Understand retrieval intent without rewriting clinical facts or diagnosing."""
import json
import re
import unicodedata

from knowledge_search import fold, query_topics, nonmedical_positions


def one_burn_spelling_edit(word):
    """Nominate a spelling confirmation, never silently correct a condition."""
    target='bong'
    if word==target or abs(len(word)-len(target))>1:
        return False
    if len(word)==len(target):
        differences=[i for i,(a,b) in enumerate(zip(word,target)) if a!=b]
        return (len(differences)==2
                and differences[1]==differences[0]+1
                and word[differences[0]]==target[differences[1]]
                and word[differences[1]]==target[differences[0]])
    short,long=(word,target) if len(word)<len(target) else (target,word)
    return any(long[:i]+long[i+1:]==short for i in range(len(long)))


def contextual_burn_typo(original,words):
    body={'tay','chan','da','mieng','mat','dau','lung'}
    # These are valid non-injury expressions; proximity to "tay" is not enough.
    benign=('bon phan','bon cay','bon rut','bon hoa','tay sai','bon rua','ong dot')
    text=' '.join(words)
    if any(re.search(r'\b'+phrase+r'\b',text) for phrase in benign):
        return None
    for index,word in enumerate(words):
        if word in {'bang','ong'} or original[index]=='bốn' or not one_burn_spelling_edit(word):
            continue
        after=index+1<len(words) and words[index+1] in body and original[index+1] not in {'đá','tây','đau'}
        before=any(words[i] in body and original[i] not in {'đá','tây','đau'}
                   for i in range(max(0,index-4),index)) and 'bi' in words[max(0,index-3):index]
        if after or before:
            return original[index]
    return None


def local_intent(query):
    query=unicodedata.normalize('NFC',query)
    original = re.findall(r'\w+', unicodedata.normalize('NFC', query.casefold()))
    words = [fold(word) for word in original]
    positive, negative, _ = query_topics(query)
    # These are suggestions, not automatic corrections: a misspelling can change
    # the condition. A confirmation is a new explicit user statement.
    for index, word in enumerate(original):
        if word in {'bỏn', 'bổng', 'bõng', 'bongg'}:
            if index+1 < len(words) and words[index+1] == 'ngo':
                return {'intent':'unclear', 'reason':'possible_typo',
                        'answer':'Bạn muốn hỏi về món bỏng ngô hay đang bị tổn thương do bỏng? Hãy nói rõ hơn để tôi tìm đúng thông tin.'}
            return {'intent': 'unclear', 'reason': 'possible_typo',
                    'suggested_query': re.sub(r'\b' + re.escape(word) + r'\b', 'bỏng', query, flags=re.I),
                    'answer': 'Bạn muốn nói bị bỏng phải không? Hãy nhập lại câu với từ “bỏng” nếu đúng, hoặc mô tả rõ chỗ đang bị tổn thương.'}
    typo=contextual_burn_typo(original,words)
    if typo is not None:
        proposed=re.sub(r'\b'+re.escape(typo)+r'\b','bỏng',query,flags=re.I)
        return {'intent':'unclear','reason':'possible_typo','suggested_query':proposed,
                'answer':'Có phải bạn muốn viết “'+proposed+'”? Nếu chưa đúng, hãy viết lại hoặc mô tả rõ ý bạn muốn hỏi. Tôi chưa đưa ra hướng dẫn khi từ này còn chưa rõ.'}
    ignored = nonmedical_positions(original, words)
    harm = {'bi', 'dau', 'rat', 'chay', 'hoc', 'nghen', 'thuong', 'phong', 'sung', 'mau'}
    if ignored and not positive and not (set(words) & harm):
        return {'intent': 'other', 'reason': 'nonmedical_phrase',
                'topic_hint': 'popcorn' if 'bong ngo' in fold(query) else 'nonmedical'}
    if not positive and negative:
        return {'intent': 'unclear', 'reason': 'negated_topic',
                'answer': 'Bạn đang phủ định tổn thương này. Bạn muốn hỏi thông tin chung hay mô tả một vấn đề khác?'}
    # Unaccented "bong" and lookalike words may mean a ball, flower or burn.
    ambiguous = any(word in {'bong', 'bóng', 'bông', 'bồng', 'phong', 'phòng'}
                    and index not in ignored for index, word in enumerate(original))
    if ambiguous and (not positive or 'thermal_burn' in positive):
        return {'intent': 'unknown', 'reason': 'ambiguous_word'}
    if ('la gi' in fold(query) or any(word in words for word in ('thich', 'gia', 'ngon', 'dep'))
            or any(phrase in fold(query) for phrase in ('nong bong', 'bong long', 'cat tay ao'))):
        return {'intent': 'unknown', 'reason': 'context_needed'}
    clinical_cues = {'bi', 'vet', 'tay', 'chan', 'da', 'mieng', 'mat', 'dau', 'rat',
                     'nhiet', 'soi', 'mau', 'thuong', 'nhiem', 'bong', 'xuoc', 'tray'}
    # The alias alone does not authorize a fast path in a longer sentence with
    # no injury context (e.g. a metaphor). Let AI read those sentences as a whole.
    surrounding = set(words) - {'bong', 'xuoc', 'tray', 'bam', 'phong'}
    if positive and len(words) > 3 and not (surrounding & clinical_cues):
        return {'intent': 'unknown', 'reason': 'context_needed'}
    return {'intent': 'first_aid' if positive else 'unknown', 'reason': 'explicit_topic' if positive else 'unrecognized_expression'}


def understanding_prompt(candidates):
    return json.dumps({'documents': [{'id': entry['id'], 'title': entry['title']}
                                    for entry in candidates]}, ensure_ascii=False)


def validate_understanding(raw, allowed_ids):
    raw = raw.strip()
    fenced = re.fullmatch(r'```(?:json)?\s*(.*?)\s*```', raw, re.S)
    if fenced:
        raw = fenced.group(1)
    value = json.loads(raw)
    if not isinstance(value, dict) or set(value) != {'intent', 'search_query', 'entry_ids', 'needs_clarification'}:
        raise ValueError('Unexpected interpretation fields')
    intent, ids = value['intent'], value['entry_ids']
    if (intent not in {'first_aid', 'other', 'unclear'}
            or not isinstance(value['search_query'], str) or len(value['search_query']) > 400
            or type(value['needs_clarification']) is not bool
            or not isinstance(ids, list) or len(ids) > 2
            or any(type(i) is not int or i not in allowed_ids for i in ids)
            or len(set(ids)) != len(ids)):
        raise ValueError('Invalid interpretation')
    if intent == 'other' and (ids or value['needs_clarification']):
        raise ValueError('Nonmedical query cannot select first-aid references')
    if intent == 'unclear' and (ids or not value['needs_clarification']):
        raise ValueError('Ambiguous query must ask for clarification')
    return value
