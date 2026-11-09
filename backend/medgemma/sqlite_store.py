"""Local knowledge management. Source review never becomes clinical approval implicitly."""
from contextlib import closing
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import sqlite3


class StoreError(Exception):
    def __init__(self, message, status=400):
        self.status = status
        super().__init__(message)


def digest(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


class SQLiteStore:
    def __init__(self, path, source_root=None, allow_source_demo=False):
        self.path = Path(path).resolve()
        self.source_root = Path(source_root).resolve() if source_root else self.path.parent.parent
        self.allow_source_demo = allow_source_demo

    @staticmethod
    def clinical_publication():
        return {'kind':'clinical_approved','label':'Đã duyệt chuyên môn','clinical_reviewed':True}

    def _demo_entries(self, db):
        if not self.allow_source_demo:return {}
        try:
            manifest=json.loads((self.path.parent/'demo_publication.json').read_text(encoding='utf-8'))
            if (manifest.get('schema_version')!=1 or manifest.get('enabled') is not True
                    or manifest.get('scope')!='academic_demo' or not isinstance(manifest.get('entries'),list)):
                return {}
            records={}
            verified_files={}
            approved_slugs={r[0] for r in db.execute('SELECT slug FROM published_entries')}
            for record in manifest['entries']:
                if (not isinstance(record,dict) or type(record.get('id')) is not int
                        or not isinstance(record.get('content_sha256'),str)):
                    continue
                try:item=self._content(db,record['id'])
                except StoreError:continue
                if (item['status']!='in_review' or item['version']!=item['latest_version']
                        or item['slug'] in approved_slugs or item['slug']!=record.get('slug')
                        or item['version']!=record.get('version') or not item['steps'] or not item['warnings']
                        or not item['applicability'] or not item['exclusions']
                        or self._reference_fingerprint(item)!=record['content_sha256']):
                    continue
                review=self.source_review(item)
                if review['state']!='checked':continue
                if not any(c['role']=='primary' and c['variant']=='original' for c in item['citations']):continue
                for citation in item['citations']:
                    key=citation['file_id']
                    if key not in verified_files:
                        try:self.file_path(key);verified_files[key]=True
                        except StoreError:verified_files[key]=False
                if not all(verified_files[c['file_id']] for c in item['citations']):continue
                records[item['id']]={'kind':'source_reviewed_demo','clinical_reviewed':False,
                                     'label':'Đã đối chiếu nguồn — chưa duyệt chuyên môn',
                                     'scope':'academic_demo','checked_at':review['checked_at'],
                                     'clinical_hold':review['clinical_hold']}
            return records
        except (OSError,ValueError,KeyError,TypeError):
            return {}

    def connect(self, write=False):
        if not self.path.is_file():
            raise StoreError('Chưa tìm thấy kho hướng dẫn SQLite.', 503)
        db = sqlite3.connect(self.path.as_uri() + ('?mode=rw' if write else '?mode=ro'), uri=True, timeout=5)
        db.row_factory = sqlite3.Row
        db.execute('PRAGMA foreign_keys=ON')
        return db

    @staticmethod
    def _content(db, entry_id):
        row = db.execute('SELECT * FROM knowledge_entries WHERE id=?', (entry_id,)).fetchone()
        if row is None:
            raise StoreError('Không tìm thấy hướng dẫn.', 404)
        item = dict(row)
        item['injury_types'] = [dict(r) for r in db.execute('SELECT t.code,t.name_vi FROM entry_injury_types e JOIN injury_types t ON t.code=e.injury_code WHERE e.entry_id=? ORDER BY t.code', (entry_id,))]
        item['steps'] = [dict(r) for r in db.execute('SELECT * FROM care_steps WHERE entry_id=? ORDER BY step_number', (entry_id,))]
        item['warnings'] = [dict(r) for r in db.execute('SELECT * FROM warnings WHERE entry_id=? ORDER BY id', (entry_id,))]
        item['citations'] = [dict(r) for r in db.execute('SELECT c.*,f.relative_path,f.sha256,f.variant,f.language,f.page_count,s.title AS source_title,s.url,s.doi FROM entry_citations c JOIN source_files f ON f.id=c.file_id JOIN sources s ON s.id=f.source_id WHERE c.entry_id=? ORDER BY c.id', (entry_id,))]
        item['latest_version'] = db.execute('SELECT max(version) FROM knowledge_entries WHERE slug=?', (item['slug'],)).fetchone()[0]
        # This digest includes review state as well as content for optimistic concurrency.
        item['revision'] = digest(item)
        return item

    @staticmethod
    def _reference_fingerprint(item):
        payload = {k: item[k] for k in ('slug','version','title','summary','applicability','exclusions','review_notes')}
        payload['injury_types'] = sorted(t['code'] for t in item['injury_types'])
        payload['care_steps'] = [{k:r[k] for k in ('step_number','instruction')} for r in item['steps']]
        payload['warnings'] = [{k:r[k] for k in ('severity','description','action')} for r in item['warnings']]
        keys = ('file_id','pdf_page_start','pdf_page_end','printed_pages','section','role','recommendation_class','evidence_level','interpretation_note')
        payload['entry_citations'] = [{k:r[k] for k in keys} for r in item['citations']]
        files = {r['file_id']:r['sha256'] for r in item['citations']}
        payload['source_file_hashes'] = [{'file_id':key,'sha256':files[key]} for key in sorted(files)]
        return digest(payload)

    def source_review(self, item):
        try:
            report = json.loads((self.path.parent/'ket_qua_ra_soat.json').read_text(encoding='utf-8'))
            for record in report['entry_records']:
                if (record['slug'],record['version']) == (item['slug'],item['version']):
                    return {'state':'checked' if record['content_sha256']==self._reference_fingerprint(item) else 'changed',
                            'checked_at':record['checked_at_utc'],'clinical_hold':record['clinical_hold']}
        except (OSError, ValueError, KeyError, TypeError):
            pass
        return {'state':'not_checked','clinical_hold':'Chưa có kết quả đối chiếu nguồn cho phiên bản này.'}

    def summary(self):
        with closing(self.connect()) as db:
            counts = {r['status']:r['n'] for r in db.execute('SELECT status,count(*) n FROM knowledge_entries GROUP BY status')}
            return {'counts':{state:counts.get(state,0) for state in ('draft','in_review','approved','retired')},
                    'published':db.execute('SELECT count(*) FROM published_entries').fetchone()[0],
                    'demo_published':len(self._demo_entries(db)),
                    'sources':db.execute('SELECT count(*) FROM sources').fetchone()[0],
                    'injury_types':[dict(r) for r in db.execute('SELECT * FROM injury_types ORDER BY code')],
                    'gaps':[dict(r) for r in db.execute("SELECT * FROM coverage_gaps WHERE status='open' ORDER BY id")]}

    def list_entries(self, published=False):
        table = 'published_entries' if published else 'knowledge_entries'
        with closing(self.connect()) as db:
            ids = [r[0] for r in db.execute(f'SELECT id FROM {table} ORDER BY slug,version DESC')]
            demo=self._demo_entries(db)
            if published:ids+=sorted(identifier for identifier in demo if identifier not in ids)
            entries = []
            for entry_id in ids:
                item = self._content(db,entry_id)
                entry = {k:item[k] for k in ('id','slug','version','title','summary','status','injury_types','latest_version')}
                if not published:entry['source_review'] = self.source_review(item)
                if item['status']=='approved':entry['publication']=self.clinical_publication()
                elif entry_id in demo:entry['publication']=demo[entry_id]
                entries.append(entry)
            return entries

    def detail(self, entry_id, published=False):
        with closing(self.connect()) as db:
            demo=self._demo_entries(db)
            clinically_published=db.execute('SELECT 1 FROM published_entries WHERE id=?',(entry_id,)).fetchone()
            if published and not clinically_published and entry_id not in demo:
                raise StoreError('Hướng dẫn này chưa được xuất bản hoặc đã ngừng sử dụng.',404)
            item = self._content(db,entry_id)
            if clinically_published:item['publication']=self.clinical_publication()
            elif entry_id in demo:item['publication']=demo[entry_id]
            if not published:
                item['source_review'] = self.source_review(item)
                item['history'] = [dict(r) for r in db.execute('SELECT * FROM review_history WHERE entry_id=? ORDER BY id',(entry_id,))]
            else:
                for key in ('revision','review_notes','review_note','reviewer','reviewed_at','latest_version'):
                    item.pop(key,None)
            return item

    def file_path(self, file_id):
        with closing(self.connect()) as db:
            row = db.execute('SELECT relative_path,sha256 FROM source_files WHERE id=?',(file_id,)).fetchone()
            if not row:raise StoreError('Không tìm thấy tài liệu nguồn.',404)
        path = (self.source_root/row['relative_path']).resolve()
        if not path.is_relative_to((self.source_root/'TaiLieuNguon').resolve()) or path.suffix.lower()!='.pdf' or not path.is_file():
            raise StoreError('Đường dẫn tài liệu nguồn không hợp lệ.',404)
        with path.open('rb') as source:
            if hashlib.file_digest(source,'sha256').hexdigest()!=row['sha256']:
                raise StoreError('File nguồn đã thay đổi so với bản được trích dẫn. Cần đối chiếu lại tài liệu.',409)
        return path

    @staticmethod
    def _text(payload,key,maximum,required=True):
        value = payload.get(key,'')
        if not isinstance(value,str) or len(value)>maximum or (required and not value.strip()):
            raise StoreError('Nội dung trường '+key+' chưa hợp lệ.')
        return value.strip()

    def save(self, entry_id, payload):
        fields = {k:self._text(payload,k,500 if k=='title' else 6000,required=k!='review_notes')
                  for k in ('title','summary','applicability','exclusions','review_notes')}
        steps = payload.get('steps')
        warnings = payload.get('warnings')
        if not isinstance(steps,list) or not 1<=len(steps)<=30 or any(not isinstance(s,str) or not s.strip() or len(s)>2000 for s in steps):
            raise StoreError('Cần từ 1 đến 30 bước có nội dung.')
        if not isinstance(warnings,list) or not 1<=len(warnings)<=30:
            raise StoreError('Cần ít nhất một cảnh báo.')
        cleaned = []
        for warning in warnings:
            if not isinstance(warning,dict) or warning.get('severity') not in {'emergency','seek_care','avoid','caution'}:
                raise StoreError('Loại cảnh báo chưa hợp lệ.')
            cleaned.append({'severity':warning['severity'],
                            'description':self._text(warning,'description',2000),
                            'action':self._text(warning,'action',2000)})
        with closing(self.connect(write=True)) as db, db:
            db.execute('BEGIN IMMEDIATE')
            current = self._content(db,entry_id)
            self._check_revision(current,payload)
            if current['status'] not in {'draft','in_review'}:
                raise StoreError('Bản đã duyệt được giữ nguyên. Hãy tạo phiên bản nháp mới.',409)
            db.execute('UPDATE knowledge_entries SET '+','.join(k+'=?' for k in fields)+",status='draft' WHERE id=?",(*fields.values(),entry_id))
            db.execute('DELETE FROM care_steps WHERE entry_id=?',(entry_id,))
            db.executemany('INSERT INTO care_steps(entry_id,step_number,instruction) VALUES(?,?,?)',[(entry_id,i,s.strip()) for i,s in enumerate(steps,1)])
            db.execute('DELETE FROM warnings WHERE entry_id=?',(entry_id,))
            db.executemany('INSERT INTO warnings(entry_id,severity,description,action) VALUES(?,?,?,?)',[(entry_id,w['severity'],w['description'],w['action']) for w in cleaned])
        return self.detail(entry_id)

    @staticmethod
    def _check_revision(item,payload):
        if payload.get('revision')!=item['revision']:
            raise StoreError('Nội dung đã thay đổi ở lượt khác. Hãy tải lại trước khi tiếp tục.',409)

    def action(self, entry_id, payload):
        action = payload.get('action')
        if action not in {'in_review','approve','retire','new_version'}:
            raise StoreError('Thao tác chưa hợp lệ.')
        reviewer = note = ''
        if action=='approve':
            reviewer = self._text(payload,'reviewer',200)
            note = self._text(payload,'review_note',6000)
            if payload.get('clinical_attestation') is not True:
                raise StoreError('Cần xác nhận việc duyệt chuyên môn thực tế; đối chiếu nguồn bằng AI chưa đủ để xuất bản.')
        with closing(self.connect(write=True)) as db, db:
            db.execute('BEGIN IMMEDIATE')
            current = self._content(db,entry_id)
            self._check_revision(current,payload)
            if action=='approve':
                if current['status'] not in {'draft','in_review'} or current['version']!=current['latest_version']:
                    raise StoreError('Chỉ duyệt phiên bản mới nhất đang chờ duyệt.',409)
                # Retire old approvals in the same transaction. Failure rolls back both operations.
                db.execute("UPDATE knowledge_entries SET status='retired' WHERE slug=? AND status='approved'",(current['slug'],))
                try:
                    db.execute("UPDATE knowledge_entries SET status='approved',reviewer=?,reviewed_at=?,review_note=? WHERE id=?",
                               (reviewer,datetime.now(timezone.utc).isoformat(),note,entry_id))
                except sqlite3.IntegrityError as exc:
                    raise StoreError('Chưa đủ điều kiện duyệt: cần nguồn gốc, điều kiện áp dụng, bước và cảnh báo hợp lệ.',409) from exc
            elif action=='in_review':
                if current['status']!='draft':raise StoreError('Chỉ chuyển bản nháp sang chờ duyệt.',409)
                db.execute("UPDATE knowledge_entries SET status='in_review' WHERE id=?",(entry_id,))
            elif action=='retire':
                if current['status']!='approved':raise StoreError('Chỉ ngừng sử dụng bản đang được duyệt.',409)
                db.execute("UPDATE knowledge_entries SET status='retired' WHERE id=?",(entry_id,))
            else:
                keys = ('slug','title','summary','applicability','exclusions','review_notes')
                version = current['latest_version']+1
                cursor = db.execute('INSERT INTO knowledge_entries('+','.join(keys)+',version) VALUES('+','.join('?' for _ in range(len(keys)+1))+')',(*[current[k] for k in keys],version))
                newer = cursor.lastrowid
                db.execute('INSERT INTO entry_injury_types SELECT ?,injury_code FROM entry_injury_types WHERE entry_id=?',(newer,entry_id))
                db.execute('INSERT INTO care_steps(entry_id,step_number,instruction) SELECT ?,step_number,instruction FROM care_steps WHERE entry_id=?',(newer,entry_id))
                db.execute('INSERT INTO warnings(entry_id,severity,description,action) SELECT ?,severity,description,action FROM warnings WHERE entry_id=?',(newer,entry_id))
                keys = ('file_id','pdf_page_start','pdf_page_end','printed_pages','section','role','recommendation_class','evidence_level','interpretation_note')
                db.execute('INSERT INTO entry_citations(entry_id,'+','.join(keys)+') SELECT ?,'+','.join(keys)+' FROM entry_citations WHERE entry_id=?',(newer,entry_id))
                entry_id = newer
        return self.detail(entry_id)
