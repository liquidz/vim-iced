let s:suite  = themis#suite('iced.nrepl.bencode')
let s:assert = themis#helper('assert')

"" ENCODING TEST

function! s:suite.encode_string_test() abort
  call s:assert.equals('5:hello', iced#nrepl#bencode#encode('hello'))
  call s:assert.equals('0:', iced#nrepl#bencode#encode(''))
  call s:assert.equals('0:', iced#nrepl#bencode#encode(v:none))
endfunction

function! s:suite.encode_number_test() abort
  call s:assert.equals('i1024e', iced#nrepl#bencode#encode(1024))
endfunction

function! s:suite.encode_list_test() abort
  call s:assert.equals('l3:fooi123ee', iced#nrepl#bencode#encode(['foo', 123]))
  call s:assert.equals('l3:fooli123eee', iced#nrepl#bencode#encode(['foo', [123]]))
  call s:assert.equals('le', iced#nrepl#bencode#encode([]))
  call s:assert.equals('l0:e', iced#nrepl#bencode#encode(['']))
endfunction

function! s:suite.encode_dict_test() abort
  call s:assert.equals('d3:fooi123ee', iced#nrepl#bencode#encode({'foo': 123}))
  call s:assert.equals('d3:fool3:bari123eee', iced#nrepl#bencode#encode({'foo': ['bar', 123]}))
  call s:assert.equals('d3:food3:bari123eee', iced#nrepl#bencode#encode({'foo': {'bar': 123}}))
  call s:assert.equals('de', iced#nrepl#bencode#encode({}))
  call s:assert.equals('d3:foo0:e', iced#nrepl#bencode#encode({'foo': ''}))
  call s:assert.equals('d3:foo0:e', iced#nrepl#bencode#encode({'foo': v:none}))
endfunction
