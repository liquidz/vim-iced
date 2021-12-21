#!/usr/bin/python3

def __decode_string(b, start=0):
    """
    >>> __decode_string(b'3:foo3:bar')
    {'value': 'foo', 'start': 5}
    >>> __decode_string(b'3:foo3:bar', start=5)
    {'value': 'bar', 'start': 10}
    >>> __decode_string(b'0:3:bar')
    {'value': '', 'start': 2}
    """
    cpos = b.find(b':', start)
    if cpos == -1:
        raise Exception('failed to decode string token', b[start:])
    l = int(b[start:cpos])
    return {'value': b[cpos+1:cpos+1+l].decode(encoding='utf-8'), 'start': cpos+1+l}

def __decode_integer(b, start=0):
    """
    >>> __decode_integer(b'i123e3:foo')
    {'value': 123, 'start': 5}
    >>> __decode_integer(b'i123ei4567e', start=5)
    {'value': 4567, 'start': 11}
    """
    epos = b.find(b'e', start)
    if epos == -1:
        raise Exception('failed to decode integer token')
    return {'value': int(b[start+1:epos]), 'start': epos+1}

def __decode_list(b, start=0):
    """
    >>> __decode_list(b'li123e3:foo0:e3:bar')
    {'value': [123, 'foo', ''], 'start': 14}
    >>> __decode_list(b'lel3:bare')
    {'value': [], 'start': 2}
    >>> __decode_list(b'lel3:bare', start=2)
    {'value': ['bar'], 'start': 9}
    >>> __decode_list(b'llee3:bar')
    {'value': [[]], 'start': 4}
    """
    start += 1
    result = []
    while chr(b[start]) != 'e':
        decoded = __decode(b, start)
        result.append(decoded['value'])
        start = decoded['start']
    return {'value': result, 'start': start+1}

def __decode_dict(b, start=0):
    """
    >>> __decode_dict(b'd3:fooi123ee3:bar')
    {'value': {'foo': 123}, 'start': 12}
    >>> __decode_dict(b'de3:bar')
    {'value': {}, 'start': 2}
    >>> __decode_dict(b'ded3:bari1ee', start=2)
    {'value': {'bar': 1}, 'start': 12}
    """
    start += 1
    result = {}
    while chr(b[start]) != 'e':
        k = __decode(b, start)
        v = __decode(b, k['start'])
        result[k['value']] = v['value']
        start = v['start']
    return {'value': result, 'start': start+1}

def __decode(b, start=0):
    c = chr(b[start])
    if c in {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}:
        return __decode_string(b, start)
    elif c == 'i':
        return __decode_integer(b, start)
    elif c == 'l':
        return __decode_list(b, start)
    elif c == 'd':
        return __decode_dict(b, start)
    raise Exception('invalid token ' + c)

def iced_bencode_decode(s):
    """
    >>> iced_bencode_decode('3:foo')
    'foo'
    >>> iced_bencode_decode('3:foo3:bar')
    ['foo', 'bar']
    >>> iced_bencode_decode('3:fooo')
    '__FAILED__'
    >>> iced_bencode_decode('i123')
    '__FAILED__'
    >>> iced_bencode_decode('li123e')
    '__FAILED__'
    >>> iced_bencode_decode('d3:fooi123e')
    '__FAILED__'
    >>> iced_bencode_decode('d3:foo')
    '__FAILED__'
    >>> iced_bencode_decode('d3:fooo')
    '__FAILED__'
    """
    result = []
    b = s.encode('utf-8')
    start = 0
    try:
        while start < len(b):
            ret = __decode(b, start)
            result.append(ret['value'])
            start = ret['start']
        if len(result) == 1:
            return result[0]
        return result
    except Exception:
        return '__FAILED__'

def iced_vim_repr(x):
    """
    >>> iced_vim_repr('foo')
    '"foo"'
    >>> iced_vim_repr('"foo"')
    '"\\\\"foo\\\\""'
    >>> iced_vim_repr('foo\\n')
    '"foo\\\\n"'
    >>> iced_vim_repr('foo\d')
    '"foo\\\\\\\\d"'
    >>> iced_vim_repr('foo\\d')
    '"foo\\\\\\\\d"'
    >>> iced_vim_repr(123)
    '123'
    >>> iced_vim_repr(['foo', 123])
    '["foo",123]'
    >>> iced_vim_repr({'foo': 123})
    '{"foo":123}'
    """
    t = type(x)
    if t is str:
        return '"' + x.replace('\\', '\\\\').replace('\n', '\\n').replace('"', '\\"') + '"'
    elif t is int:
        return str(x)
    elif t is list:
        ret = [iced_vim_repr(e) for e in x]
        return '[' + ','.join(ret) + ']'
    elif t is dict:
        ret = [iced_vim_repr(k) + ':' + iced_vim_repr(v) for k,v in x.items()]
        return '{' + ','.join(ret) + '}'
    raise Exception
