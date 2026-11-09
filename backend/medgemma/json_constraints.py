"""Finite JSON choices for intent/reference selection, never clinical generation."""
import json


def interpretation_options(documents):
    options = [dict(intent=intent, search_query='', entry_ids=[], needs_clarification=unclear)
               for intent, unclear in (('other', False), ('unclear', True), ('first_aid', False))]
    for first in documents:
        for ids in ([first['id']], *([first['id'], second['id']] for second in documents if second['id'] != first['id'])):
            options.append(dict(intent='first_aid', search_query=first['title'][:120],
                                entry_ids=ids, needs_clarification=False))
    return [json.dumps(option, ensure_ascii=False, separators=(',', ':')) for option in options]


def constrain_json(tokenizer, options, input_length, eos_token_ids):
    trie = {}
    for option in options:
        node = trie
        for token in tokenizer.encode(option, add_special_tokens=False):
            node = node.setdefault(token, {})
        node[None] = True
    endings = eos_token_ids if isinstance(eos_token_ids, (list, tuple)) else [eos_token_ids]
    endings = [token for token in endings if type(token) is int]
    if not endings:
        raise ValueError('No end token configured')

    def allowed_tokens(batch_id, token_ids):
        node = trie
        for token in token_ids[input_length:].tolist():
            if token not in node:
                raise ValueError('Generation left the JSON grammar')
            node = node[token]
        return [token for token in node if token is not None] + (endings if None in node else [])

    return allowed_tokens
