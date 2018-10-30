let s:suite  = themis#suite('iced.dicon.bencode.vim')
let s:assert = themis#helper('assert')

function! s:assert_parse_failure(f) abort
  try
    call a:f()
    call s:assert.fail('must be errored')
  catch /^Failed to parse/
    call s:assert.true(1)
  catch
    call s:assert.fail('unexpected error: ' . v:exception)
  endtry
endfunction

"" ENCODING TEST

function! s:suite.encode_string_test() abort
  call iced#di#register('bencode', function('iced#di#bencode#vim#build'))

  call s:assert.equals('5:hello', iced#di#get('bencode').encode('hello'))
  call s:assert.equals('0:', iced#di#get('bencode').encode(''))
  call s:assert.equals('0:', iced#di#get('bencode').encode(v:none))
endfunction

function! s:suite.encode_number_test() abort
  call iced#di#register('bencode', function('iced#di#bencode#vim#build'))

  call s:assert.equals('i1024e', iced#di#get('bencode').encode(1024))
endfunction

function! s:suite.encode_list_test() abort
  call iced#di#register('bencode', function('iced#di#bencode#vim#build'))

  call s:assert.equals('l3:fooi123ee', iced#di#get('bencode').encode(['foo', 123]))
  call s:assert.equals('l3:fooli123eee', iced#di#get('bencode').encode(['foo', [123]]))
  call s:assert.equals('le', iced#di#get('bencode').encode([]))
  call s:assert.equals('l0:e', iced#di#get('bencode').encode(['']))
endfunction

function! s:suite.encode_dict_test() abort
  call iced#di#register('bencode', function('iced#di#bencode#vim#build'))

  call s:assert.equals('d3:fooi123ee', iced#di#get('bencode').encode({'foo': 123}))
  call s:assert.equals('d3:fool3:bari123eee', iced#di#get('bencode').encode({'foo': ['bar', 123]}))
  call s:assert.equals('d3:food3:bari123eee', iced#di#get('bencode').encode({'foo': {'bar': 123}}))
  call s:assert.equals('de', iced#di#get('bencode').encode({}))
  call s:assert.equals('d3:foo0:e', iced#di#get('bencode').encode({'foo': ''}))
  call s:assert.equals('d3:foo0:e', iced#di#get('bencode').encode({'foo': v:none}))
endfunction

"" DECODING TEST

function! s:suite.decode_string_test() abort
  call iced#di#register('bencode', function('iced#di#bencode#vim#build'))

  call s:assert.equals('hello', iced#di#get('bencode').decode('5:hello'))
  call s:assert_parse_failure({-> iced#di#get('bencode').decode('5:helloo')})
  call s:assert_parse_failure({-> iced#di#get('bencode').decode('5hello')})
endfunction

function! s:suite.decode_integer_test() abort
  call s:assert.equals(1024, iced#di#get('bencode').decode('i1024e'))
  call s:assert_parse_failure({-> iced#di#get('bencode').decode('i1024')})
endfunction

function! s:suite.decode_list_test() abort
  call s:assert.equals(['foo', 123], iced#di#get('bencode').decode('l3:fooi123ee'))
  call s:assert.equals(['foo', [123]], iced#di#get('bencode').decode('l3:fooli123eee'))
  call s:assert.equals([], iced#di#get('bencode').decode('le'))
  call s:assert_parse_failure({-> iced#di#get('bencode').decode('li1024e')})
  call s:assert_parse_failure({-> iced#di#get('bencode').decode('li1024')})
endfunction

function! s:suite.decode_dict_test() abort
  call s:assert.equals({'foo': 123}, iced#di#get('bencode').decode('d3:fooi123ee'))
  call s:assert.equals({'foo': ['bar', 123]}, iced#di#get('bencode').decode('d3:fool3:bari123eee'))
  call s:assert.equals({'foo': {'bar': 123}}, iced#di#get('bencode').decode('d3:food3:bari123eee'))
  call s:assert.equals({}, iced#di#get('bencode').decode('de'))
  call s:assert_parse_failure({-> iced#di#get('bencode').decode('d3:fooi123e')})
  call s:assert_parse_failure({-> iced#di#get('bencode').decode('d3:fooi123')})
  call s:assert_parse_failure({-> iced#di#get('bencode').decode('d3:foo')})
  call s:assert_parse_failure({-> iced#di#get('bencode').decode('d3:fo')})
  call s:assert_parse_failure({-> iced#di#get('bencode').decode('d')})
endfunction

function! s:suite.decode_concated_test() abort
  call s:assert.equals(['foo', 123], iced#di#get('bencode').decode('3:fooi123e'))
  call s:assert.equals([{'foo': 123}, {'bar': 456}], iced#di#get('bencode').decode('d3:fooi123eed3:bari456ee'))
endfunction
