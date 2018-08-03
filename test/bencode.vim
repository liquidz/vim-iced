let s:suite  = themis#suite('iced.nrepl.bencode')
let s:assert = themis#helper('assert')

"" ENCODING TEST

function! s:suite.encode_string_test() abort
  call s:assert.equals('5:hello', iced#nrepl#bencode#encode('hello'))
endfunction

function! s:suite.encode_number_test() abort
  call s:assert.equals('i1024e', iced#nrepl#bencode#encode(1024))
endfunction

function! s:suite.encode_list_test() abort
  call s:assert.equals('l3:fooi123ee', iced#nrepl#bencode#encode(['foo', 123]))
  call s:assert.equals('l3:fooli123eee', iced#nrepl#bencode#encode(['foo', [123]]))
  call s:assert.equals('le', iced#nrepl#bencode#encode([]))
endfunction

function! s:suite.encode_dict_test() abort
  call s:assert.equals('d3:fooi123ee', iced#nrepl#bencode#encode({'foo': 123}))
  call s:assert.equals('d3:fool3:bari123eee', iced#nrepl#bencode#encode({'foo': ['bar', 123]}))
  call s:assert.equals('d3:food3:bari123eee', iced#nrepl#bencode#encode({'foo': {'bar': 123}}))
  call s:assert.equals('de', iced#nrepl#bencode#encode({}))
endfunction

"" DECODING TEST

function! s:suite.decode_string_test() abort
  call s:assert.equals('hello', iced#nrepl#bencode#decode('5:hello'))
endfunction

function! s:suite.decode_number_test() abort
  call s:assert.equals(1024, iced#nrepl#bencode#decode('i1024e'))
endfunction

function! s:suite.decode_list_test() abort
  call s:assert.equals(['foo', 123], iced#nrepl#bencode#decode('l3:fooi123ee'))
  call s:assert.equals(['foo', [123]], iced#nrepl#bencode#decode('l3:fooli123eee'))
  call s:assert.equals([], iced#nrepl#bencode#decode('le'))
endfunction

function! s:suite.decode_dict_test() abort
  call s:assert.equals({'foo': 123}, iced#nrepl#bencode#decode('d3:fooi123ee'))
  call s:assert.equals({'foo': ['bar', 123]}, iced#nrepl#bencode#decode('d3:fool3:bari123eee'))
  call s:assert.equals({'foo': {'bar': 123}}, iced#nrepl#bencode#decode('d3:food3:bari123eee'))
  call s:assert.equals({}, iced#nrepl#bencode#decode('de'))
endfunction

function! s:suite.decode_concated_test() abort
  call s:assert.equals(['foo', 123], iced#nrepl#bencode#decode('3:fooi123e'))
  call s:assert.equals([{'foo': 123}, {'bar': 456}], iced#nrepl#bencode#decode('d3:fooi123eed3:bari456ee'))
endfunction
