let s:suite  = themis#suite('iced.nrepl.bencode.vim')
let s:assert = themis#helper('assert')
let s:d = iced#nrepl#bencode#vim#new()

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

function! s:suite.decode_string_test() abort
  call s:assert.equals('hello', s:d.decode('5:hello'))
  call s:assert_parse_failure({-> s:d.decode('5:helloo')})
  call s:assert_parse_failure({-> s:d.decode('5hello')})
endfunction

function! s:suite.decode_integer_test() abort
  call s:assert.equals(1024, s:d.decode('i1024e'))
  call s:assert_parse_failure({-> s:d.decode('i1024')})
endfunction

function! s:suite.decode_list_test() abort
  call s:assert.equals(['foo', 123], s:d.decode('l3:fooi123ee'))
  call s:assert.equals(['foo', [123]], s:d.decode('l3:fooli123eee'))
  call s:assert.equals([], s:d.decode('le'))
  call s:assert_parse_failure({-> s:d.decode('li1024e')})
  call s:assert_parse_failure({-> s:d.decode('li1024')})
endfunction

function! s:suite.decode_dict_test() abort
  call s:assert.equals({'foo': 123}, s:d.decode('d3:fooi123ee'))
  call s:assert.equals({'foo': ['bar', 123]}, s:d.decode('d3:fool3:bari123eee'))
  call s:assert.equals({'foo': {'bar': 123}}, s:d.decode('d3:food3:bari123eee'))
  call s:assert.equals({}, s:d.decode('de'))
  call s:assert_parse_failure({-> s:d.decode('d3:fooi123e')})
  call s:assert_parse_failure({-> s:d.decode('d3:fooi123')})
  call s:assert_parse_failure({-> s:d.decode('d3:foo')})
  call s:assert_parse_failure({-> s:d.decode('d3:fo')})
  call s:assert_parse_failure({-> s:d.decode('d')})
endfunction

function! s:suite.decode_concated_test() abort
  call s:assert.equals(['foo', 123], s:d.decode('3:fooi123e'))
  call s:assert.equals([{'foo': 123}, {'bar': 456}], s:d.decode('d3:fooi123eed3:bari456ee'))
endfunction
