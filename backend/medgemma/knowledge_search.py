"""Vietnamese document retrieval only; aliases never select care or assign severity."""
import re
import unicodedata
from urllib.parse import urlencode

ALIASES = {
    'graze': ('tray', 'xuoc', 'xuot', 'tray xuoc', 'tro da'),
    'cut': ('vet cat', 'cat tay', 'cat chan', 'dao cat', 'dut tay', 'dut chan', 'rach da', 'vet rach'),
    'thermal_burn': ('bong', 'phong', 'bong nhiet', 'nuoc soi', 'dau soi'),
    'bruise': ('bam', 'bam tim', 'bam dap', 'vet bam'),
    'chemical_burn': ('bong hoa chat', 'bong do hoa chat', 'bong vi hoa chat', 'bong do nuoc tay', 'bong do thuoc tay', 'bong axit', 'bong do axit', 'bong vi axit', 'bong acid', 'bong kiem',
                      'axit ban', 'axit dinh', 'axit vao mat', 'hoa chat ban', 'hoa chat dinh', 'hoa chat vao mat',
                      'nuoc tay ban', 'nuoc tay dinh', 'nuoc tay vao mat'),
    'electrical_burn': ('bong dien', 'bong do dien', 'dien giat', 'dien cao the', 'day dien roi'),
}
STOPWORDS = set('toi minh ban em bi dang thi nen lam gi the nao phai hay voi va la co mot cho ve tai lieu huong dan xem tim cach nhe ngay tay chan da'.split())
NEGATIONS = {'khong', 'chua', 'chang', 'ko', 'k'}
HOMONYMS = {'bóng', 'bông', 'bồng', 'phòng'}


def nonmedical_positions(original, words):
    """Mask a nonmedical phrase, never all mentions of a word in the sentence."""
    ignored = set()
    for index in range(len(words) - 1):
        pair = words[index:index + 2]
        if pair == ['bong', 'ngo'] or original[index:index + 2] in (
                ['bóng', 'đá'], ['bóng', 'đèn'], ['bóng', 'bay'], ['bông', 'hoa']):
            ignored.update((index, index + 1))
    return ignored


def fold(text):
    text = unicodedata.normalize('NFD', text.casefold().replace('đ', 'd'))
    text = ''.join(char for char in text if not unicodedata.combining(char))
    return ' '.join(re.findall(r'\w+', text))


def query_topics(query):
    original = re.findall(r'\w+', unicodedata.normalize('NFC', query.casefold()))
    words = [fold(word) for word in original]
    positive, negative = set(), set()
    ignored = nonmedical_positions(original, words)
    # Generic 'burn' inside a chemical/electrical phrase must not nominate the
    # thermal protocol. Track occurrences, preserving separate thermal mentions.
    special_positions = set()
    for code in ('chemical_burn', 'electrical_burn'):
        for alias in ALIASES[code]:
            phrase = alias.split()
            for start in range(len(words) - len(phrase) + 1):
                if words[start:start + len(phrase)] == phrase:
                    special_positions.update(range(start, start + len(phrase)))
    for code, aliases in ALIASES.items():
        for alias in aliases:
            phrase = alias.split()
            for start in range(len(words) - len(phrase) + 1):
                if words[start:start + len(phrase)] != phrase:
                    continue
                if code == 'thermal_burn' and any(index in special_positions for index in range(start, start + len(phrase))):
                    continue
                if any(index in ignored for index in range(start, start + len(phrase))):
                    continue
                if len(phrase) == 1 and original[start] in HOMONYMS:
                    ignored.add(start)
                    continue
                # A nearby negation prevents expansion of that mention. Do not infer
                # resolution or reverse clinical advice from a user's negation.
                negated = any(words[index] in NEGATIONS and not (index+1 < start and words[index+1] == 'biet')
                              for index in range(max(0, start - 3), start))
                (negative if negated else positive).add(code)
                if negated:
                    ignored.update(range(start, start + len(phrase)))
    # A separate generic burn mention does not establish a thermal cause when
    # the sentence specifies electricity or chemicals. Retain thermal only when
    # an independent heat phrase is present (including explicitly mixed injuries).
    if positive & {'chemical_burn', 'electrical_burn'} and 'thermal_burn' in positive:
        heat = False
        for phrase in ('bong nhiet', 'nuoc soi', 'dau soi', 'nuoc nong', 'vat nong', 'lua'):
            tokens = phrase.split()
            for start in range(len(words) - len(tokens) + 1):
                if (words[start:start + len(tokens)] == tokens
                        and not any(w in NEGATIONS for w in words[max(0, start-3):start])):
                    heat = True
        if not heat:
            positive.discard('thermal_burn')
    terms = {word for index, word in enumerate(words) if index not in ignored and word not in STOPWORDS and word not in NEGATIONS}
    return positive, negative - positive, terms


def search_documents(entries, query='', group=''):
    positive, negative, terms = query_topics(query)
    ranked = []
    for entry in entries:
        codes = {item['code'] for item in entry['injury_types']}
        if group and group not in codes:
            continue
        if codes & negative and not codes & positive:
            continue
        if not query.strip():
            ranked.append((0, entry))
            continue
        title_terms = set(fold(entry['title']).split()) - STOPWORDS
        text_terms = set(fold(entry['title'] + ' ' + entry['summary']).split()) - STOPWORDS
        shared = terms & text_terms
        topic_match = bool(codes & positive)
        # Single unfamiliar words are not enough to infer a topic; explicit aliases
        # can retrieve a group even when the document uses a different phrase.
        if topic_match or len(shared) >= 2:
            ranked.append((4 * int(topic_match) + 2 * len(terms & title_terms) + len(shared), entry))
    return [entry for _, entry in sorted(ranked, key=lambda item: (-item[0], item[1]['title']))]


def topic_links(groups, query, available_entries):
    positive, _, _ = query_topics(query)
    selected = [group for group in groups if group['code'] in positive]
    if not selected:
        selected = [group for group in groups if group['code'] in ('graze', 'cut', 'thermal_burn', 'chemical_burn', 'electrical_burn', 'bruise')]
    return [{'code':group['code'], 'name':group['name_vi'],
             'recognized':group['code'] in positive,
             'published_count':sum(any(t['code']==group['code'] for t in entry['injury_types']) for entry in available_entries),
             'url':'/knowledge?' + urlencode({'group':group['code']})} for group in selected]


def demo_reference_order(entries, query):
    """Order reference titles for common queries; never assert patient applicability."""
    words=fold(query).split()
    positive,_,_=query_topics(query)
    def mentioned(phrase):
        tokens=phrase.split()
        for start in range(len(words)-len(tokens)+1):
            if words[start:start+len(tokens)]==tokens and not any(
                    word in NEGATIONS for word in words[max(0,start-3):start]):
                return True
        return False
    slugs=[]
    if 'electrical_burn' in positive:slugs=['electrical-burn-first-aid']
    elif 'chemical_burn' in positive:
        slugs=['chemical-eye-first-aid'] if mentioned('mat') else ['chemical-skin-first-aid']
        if mentioned('mat') and any(mentioned(part) for part in ('tay','chan','da','lung')):
            slugs.append('chemical-skin-first-aid')
    elif positive=={'bruise'}:slugs=['bruise-basic-care']
    elif mentioned('nhiem trung'):slugs=['wound-infection-signs']
    elif mentioned('di vat'):slugs=['embedded-foreign-body']
    elif any(mentioned(term) for term in ('vet can','bi can','nuoc bot','vet thuong ban')):
        slugs=['dirty-wound-and-bite']
    elif mentioned('ngung chay mau'):slugs=['small-wound-cleaning','small-wound-dressing']
    elif mentioned('chay mau') or mentioned('cam mau'):
        slugs=['external-bleeding-pressure','life-threatening-bleeding']
    elif positive=={'thermal_burn'}:slugs=['thermal-burn-cooling','burn-medical-referral']
    elif (not positive & {'thermal_burn', 'chemical_burn', 'electrical_burn', 'bruise'}
          and any(mentioned(term) for term in ('sat trung', 'khu trung', 'lam sach', 've sinh', 'rua'))):
        slugs=['small-wound-cleaning','small-wound-dressing']
    elif positive=={'graze'}:slugs=['small-wound-cleaning','small-wound-dressing']
    elif positive=={'cut'}:slugs=['cut-referral','small-wound-cleaning']
    by_slug={entry['slug']:entry for entry in entries}
    preferred=[by_slug[slug] for slug in slugs if slug in by_slug]
    return preferred if preferred else entries[:2]
