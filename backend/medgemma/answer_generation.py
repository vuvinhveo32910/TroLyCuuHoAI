"""Keep hidden reasoning private and recover a missing final answer once."""


def clean_answer(text, special_tokens=()):
    start=text.rfind('<unused94>')
    if start >= 0:
        end=text.find('<unused95>',start)
        if end < 0:
            return ''
        text=text[end+len('<unused95>'):]
    for token in set(special_tokens) | {'<end_of_turn>','<start_of_turn>','<unused95>'}:
        text=text.replace(token,'')
    return text.strip()


def retry_token_ids(generated, tokenizer, original_length, input_limit, eos_ids):
    """Retain the original input and a bounded reasoning tail, then close it."""
    tokens=list(generated)
    eos=set(eos_ids if isinstance(eos_ids,(list,tuple)) else [eos_ids])
    while tokens and tokens[-1] in eos:
        tokens.pop()
    start=tokenizer.encode('<unused94>',add_special_tokens=False)
    end=tokenizer.encode('<unused95>',add_special_tokens=False)
    def positions(sequence,marker):
        return [i for i in range(len(sequence)-len(marker)+1) if sequence[i:i+len(marker)]==marker]
    openings=positions(tokens,start)
    if not openings:
        prefix=start+tokenizer.encode('thought\n',add_special_tokens=False)+end
        if original_length+len(prefix)>input_limit:
            raise ValueError('Insufficient room for final-answer recovery')
        return prefix
    if openings:
        tokens=tokens[openings[-1]:]
    closings=positions(tokens,end)
    if closings:
        tokens=tokens[:closings[0]]
    room=input_limit-original_length-len(end)
    if room < len(start):
        raise ValueError('Insufficient room for final-answer recovery')
    if len(tokens)>room:
        head=min(8,len(tokens),room)
        tail=room-head
        tokens=tokens[:head]+(tokens[-tail:] if tail else [])
    return tokens+end


def complete_answer(generate_once, recover_once, special_tokens=(), allow_recovery=True, require_complete=True):
    first=generate_once()
    final=first
    answer=clean_answer(first['raw'],special_tokens)
    recovered=False
    first_truncated=first['count']>=first['budget'] and not first.get('ended',False)
    if allow_recovery and ((not answer and '<unused94>' in first['raw']) or first_truncated):
        final=recover_once(first)
        answer=clean_answer(final['raw'],special_tokens)
        recovered=True
    truncated=final['count']>=final['budget'] and not final.get('ended',False)
    if require_complete and truncated:
        answer=''
    failure=''
    if not answer:
        if require_complete and truncated:
            failure='final_truncated_after_recovery' if recovered else 'final_truncated'
        elif recovered:
            failure='final_missing_after_recovery'
        else:
            failure='thought_without_final' if '<unused94>' in first['raw'] else 'empty_output'
    return {
        'answer':answer,
        'truncated':truncated,
        'generated_tokens':first['count']+(final['count'] if recovered else 0),
        'generation_attempts':2 if recovered else 1,
        'initial_generated_tokens':first['count'],
        'final_generated_tokens':final['count'],
        'recovered_from_thought':recovered and '<unused94>' in first['raw'],
        'failure_reason':failure,
    }
