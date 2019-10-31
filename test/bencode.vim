let s:suite  = themis#suite('iced.di.bencode.vim')
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

let s:bencode = iced#component#bencode#vim#start({})

"" ENCODING TEST

function! s:suite.encode_string_test() abort
  call s:assert.equals('5:hello', s:bencode.encode('hello'))
  call s:assert.equals('0:', s:bencode.encode(''))

  if !has('nvim')
    call s:assert.equals('0:', s:bencode.encode(v:none))
  endif
endfunction

function! s:suite.encode_number_test() abort
  call s:assert.equals('i1024e', s:bencode.encode(1024))
endfunction

function! s:suite.encode_list_test() abort
  call s:assert.equals('l3:fooi123ee', s:bencode.encode(['foo', 123]))
  call s:assert.equals('l3:fooli123eee', s:bencode.encode(['foo', [123]]))
  call s:assert.equals('le', s:bencode.encode([]))
  call s:assert.equals('l0:e', s:bencode.encode(['']))
endfunction

function! s:suite.encode_dict_test() abort
  call s:assert.equals('d3:fooi123ee', s:bencode.encode({'foo': 123}))
  call s:assert.equals('d3:fool3:bari123eee', s:bencode.encode({'foo': ['bar', 123]}))
  call s:assert.equals('d3:food3:bari123eee', s:bencode.encode({'foo': {'bar': 123}}))
  call s:assert.equals('de', s:bencode.encode({}))
  call s:assert.equals('d3:foo0:e', s:bencode.encode({'foo': ''}))

  if !has('nvim')
    call s:assert.equals('d3:foo0:e', s:bencode.encode({'foo': v:none}))
  endif
endfunction

"" DECODING TEST

function! s:suite.decode_string_test() abort
  call s:assert.equals('hello', s:bencode.decode('5:hello'))
  call s:assert_parse_failure({-> s:bencode.decode('5:helloo')})
  call s:assert_parse_failure({-> s:bencode.decode('5hello')})
endfunction

function! s:suite.decode_integer_test() abort
  call s:assert.equals(1024, s:bencode.decode('i1024e'))
  call s:assert_parse_failure({-> s:bencode.decode('i1024')})
endfunction

function! s:suite.decode_list_test() abort
  call s:assert.equals(['foo', 123], s:bencode.decode('l3:fooi123ee'))
  call s:assert.equals(['foo', [123]], s:bencode.decode('l3:fooli123eee'))
  call s:assert.equals([], s:bencode.decode('le'))
  call s:assert_parse_failure({-> s:bencode.decode('li1024e')})
  call s:assert_parse_failure({-> s:bencode.decode('li1024')})
endfunction

function! s:suite.decode_dict_test() abort
  call s:assert.equals({'foo': 123}, s:bencode.decode('d3:fooi123ee'))
  call s:assert.equals({'foo': ['bar', 123]}, s:bencode.decode('d3:fool3:bari123eee'))
  call s:assert.equals({'foo': {'bar': 123}}, s:bencode.decode('d3:food3:bari123eee'))
  call s:assert.equals({}, s:bencode.decode('de'))
  call s:assert_parse_failure({-> s:bencode.decode('d3:fooi123e')})
  call s:assert_parse_failure({-> s:bencode.decode('d3:fooi123')})
  call s:assert_parse_failure({-> s:bencode.decode('d3:foo')})
  call s:assert_parse_failure({-> s:bencode.decode('d3:fo')})
  call s:assert_parse_failure({-> s:bencode.decode('d')})
endfunction

function! s:suite.decode_concated_test() abort
  call s:assert.equals(['foo', 123], s:bencode.decode('3:fooi123e'))
  call s:assert.equals([{'foo': 123}, {'bar': 456}], s:bencode.decode('d3:fooi123eed3:bari456ee'))
endfunction
