let s:suite  = themis#suite('iced.cache')
let s:assert = themis#helper('assert')

function! s:suite.get_and_set_test() abort
  call s:assert.equals(iced#cache#get('foo'), v:none)
  call s:assert.equals(iced#cache#get('foo', 'baz'), 'baz')

  call iced#cache#set('foo', 'bar')
  call s:assert.equals(iced#cache#get('foo'), 'bar')
endfunction

function! s:suite.delete_test() abort
  call iced#cache#set('foo', 'bar')
  call s:assert.equals(iced#cache#get('foo'), 'bar')
  call iced#cache#delete('foo')
  call s:assert.equals(iced#cache#get('foo'), v:none)
endfunction

function! s:suite.merge_test() abort
  call iced#cache#set('foo', 'bar')
  call s:assert.equals(iced#cache#get('foo'), 'bar')
  call s:assert.equals(iced#cache#get('hello'), v:none)

  call iced#cache#merge({'foo': 'baz', 'hello': 'world'})
  call s:assert.equals(iced#cache#get('foo'), 'baz')
  call s:assert.equals(iced#cache#get('hello'), 'world')
endfunction

function! s:suite.clear_test() abort
  call iced#cache#merge({'foo': 'bar', 'bar': 'baz'})
  call s:assert.equals(iced#cache#get('foo'), 'bar')
  call s:assert.equals(iced#cache#get('bar'), 'baz')

  call iced#cache#clear()
  call s:assert.equals(iced#cache#get('foo'), v:none)
  call s:assert.equals(iced#cache#get('bar'), v:none)
endfunction
