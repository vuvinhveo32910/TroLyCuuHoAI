"""Exact social replies; never classify a symptom or generate first-aid advice."""
import re
import unicodedata


def social_reply(question):
    if len(question) > 160:
        return None
    text = unicodedata.normalize('NFD', question.casefold().replace('đ', 'd'))
    text = ''.join(char for char in text if not unicodedata.combining(char))
    # Preserve other characters and the entire sentence. In particular, do not
    # strip symptoms, negation, numbers, or injury emoji to manufacture a match.
    text = ' '.join(text.split()).strip(' .,!?:;…')
    if text in {'hello', 'hi', 'hey', 'alo', 'alo alo', 'chao', 'xin chao', 'chao ban'}:
        return 'Xin chào! Bạn muốn hỏi về sơ cứu hay cần tôi hỗ trợ điều gì?'
    if text in {'cam on', 'cam on ban', 'cam on nhe', 'thanks', 'thank you'}:
        return 'Rất vui được hỗ trợ bạn.'
    if text in {'tam biet', 'hen gap lai', 'bye', 'goodbye'}:
        return 'Chào bạn, hẹn gặp lại!'
    # Only this complete social statement is supported, with optional greeting.
    # "...đi chơi nhưng bị đau..." and requests about fitness to travel cannot match.
    if re.fullmatch(
        r'(?:(?:alo|hello|hi|xin chao|chao ban),? )?'
        r'(?:toi|minh|em|to) (?:muon|dinh) di (?:choi|dao)'
        r'(?: (?:hom nay|cuoi tuan))?', text
    ):
        return 'Bạn muốn đi đâu và vào lúc nào?'
    return None
