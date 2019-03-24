let s:suite  = themis#suite('iced.cache')
let s:assert = themis#helper('assert')

function! s:suite.get_and_set_test() abort
  let s:cache = iced#state#get('cache')
  call s:assert.equals(s:cache.get('foo'), '')
  call s:assert.equals(s:cache.get('foo', 'baz'), 'baz')

  call s:cache.set('foo', 'bar')
  call s:assert.equals(s:cache.get('foo'), 'bar')
endfunction

function! s:suite.delete_test() abort
  let s:cache = iced#state#get('cache')
  call s:cache.set('foo', 'bar')
  call s:assert.equals(s:cache.get('foo'), 'bar')
  call s:cache.delete('foo')
  call s:assert.equals(s:cache.get('foo'), '')
endfunction

function! s:suite.merge_test() abort
  let s:cache = iced#state#get('cache')
  call s:cache.set('foo', 'bar')
  call s:assert.equals(s:cache.get('foo'), 'bar')
  call s:assert.equals(s:cache.get('hello'), '')

  call s:cache.merge({'foo': 'baz', 'hello': 'world'})
  call s:assert.equals(s:cache.get('foo'), 'baz')
  call s:assert.equals(s:cache.get('hello'), 'world')
endfunction

function! s:suite.clear_test() abort
  let s:cache = iced#state#get('cache')
  call s:cache.merge({'foo': 'bar', 'bar': 'baz'})
  call s:assert.equals(s:cache.get('foo'), 'bar')
  call s:assert.equals(s:cache.get('bar'), 'baz')

  call s:cache.clear()
  call s:assert.equals(s:cache.get('foo'), '')
  call s:assert.equals(s:cache.get('bar'), '')
endfunction

function! s:suite.has_key_test() abort
  let s:cache = iced#state#get('cache')
  call s:cache.clear()
  call s:assert.false(s:cache.has_key('foo'))

  call s:cache.set('foo', 'bar')
  call s:assert.true(s:cache.has_key('foo'))

  call s:cache.delete('foo')
  call s:assert.false(s:cache.has_key('foo'))
endfunction

function! s:set(k, v, r) abort
  let s:cache = iced#state#get('cache')
  call s:cache.set(a:k, a:v)
  return a:r
endfunction

function! s:suite.do_once_test() abort
  let s:cache = iced#state#get('cache')
  call s:cache.clear()
  call s:set('i', 1, v:true)

  call s:cache.do_once('foo', {-> s:set('i', s:cache.get('i') + 1, v:true)})
  call s:assert.equals(s:cache.get('i'), 2)
  call s:cache.do_once('foo', {-> s:set('i', s:cache.get('i') + 1, v:true)})
  call s:assert.equals(s:cache.get('i'), 2)

  call s:cache.do_once('bar', {-> s:set('i', s:cache.get('i') + 1, v:false)})
  call s:assert.equals(s:cache.get('i'), 3)
  call s:cache.do_once('bar', {-> s:set('i', s:cache.get('i') + 1, v:false)})
  call s:assert.equals(s:cache.get('i'), 4)
endfunction
