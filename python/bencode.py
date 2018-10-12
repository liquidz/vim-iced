#!/usr/bin/python3

def __decode_string(s):
    """
    >>> __decode_string('3:foo3:bar')
    {'value': 'foo', 'rest': '3:bar'}
    >>> __decode_string('0:3:bar')
    {'value': '', 'rest': '3:bar'}
    """
    i = s.find(':')
    if i == -1:
        raise Exception('failed to decode string token', s)
    else:
        l = int(s[:i])
        b = s[i+1:].encode()
        return {'value': b[:l].decode(encoding='utf-8'), 'rest': b[l:].decode(encoding='utf-8')}

def __decode_integer(s):
    """
    >>> __decode_integer('i123e3:foo')
    {'value': 123, 'rest': '3:foo'}
    """
    i = s.find('e')
    if i == -1:
        raise Exception('failed to decode integer token')
    else:
        return {'value': int(s[1:i]), 'rest': s[i+1:]}

def __decode_list(s):
    """
    >>> __decode_list('li123e3:foo0:e3:bar')
    {'value': [123, 'foo', ''], 'rest': '3:bar'}
    >>> __decode_list('le3:bar')
    {'value': [], 'rest': '3:bar'}
    >>> __decode_list('llee3:bar')
    {'value': [[]], 'rest': '3:bar'}
    """
    rest = s[1:]
    result = []
    while rest[0] != 'e':
        decoded = __decode(rest)
        result.append(decoded['value'])
        rest = decoded['rest']
    return {'value': result, 'rest': rest[1:]}

def __decode_dict(s):
    """
    >>> __decode_dict('d3:fooi123ee3:bar')
    {'value': {'foo': 123}, 'rest': '3:bar'}
    >>> __decode_dict('de3:bar')
    {'value': {}, 'rest': '3:bar'}
    """
    rest = s[1:]
    result = {}
    while rest[0] != 'e':
        k = __decode(rest)
        v = __decode(k['rest'])
        result[k['value']] = v['value']
        rest = v['rest']
    return {'value': result, 'rest': rest[1:]}

def __decode(s):
    c = s[0]
    if c in {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}:
        return __decode_string(s)
    elif c == 'i':
        return __decode_integer(s)
    elif c == 'l':
        return __decode_list(s)
    elif c == 'd':
        return __decode_dict(s)
    else:
        raise Exception('invalid token')

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
    rest = s
    try:
        while rest != '':
            ret = __decode(rest)
            result.append(ret['value'])
            rest = ret['rest']
        if len(result) == 1:
            return result[0]
        else:
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
    else:
        raise Exception
