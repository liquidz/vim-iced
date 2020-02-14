let s:suite  = themis#suite('iced.system')
let s:assert = themis#helper('assert')
let s:count = 0

function! s:start_component(name, this) abort
  let d = {'name': a:name, 'count': s:count, 'this': copy(a:this)}
  let s:count += 1
  return d
endfunction

function! s:setup() abort
  let s:count = 0
  call iced#system#set_component('test_foo', {
        \ 'start': funcref('s:start_component', ['foo'])})
  call iced#system#set_component('test_bar', {
        \ 'start': funcref('s:start_component', ['bar']),
        \ 'requires': ['test_foo']})
  call iced#system#set_component('test_baz', {
        \ 'start': funcref('s:start_component', ['baz']),
        \ 'requires': ['test_bar']})
endfunction

" function! s:suite.requires_test() abort
"   call s:setup()
"   call s:assert.equals([], iced#system#requires('test_foo'))
"   call s:assert.equals(['test_foo'], iced#system#requires('test_bar'))
"   call s:assert.equals(['test_bar'], iced#system#requires('test_baz'))
" endfunction

" function! s:suite.all_requires_test() abort
"   call s:setup()
"   call s:assert.equals([], iced#system#all_requires('test_foo'))
"   call s:assert.equals(['test_foo'], iced#system#all_requires('test_bar'))
"   call s:assert.equals(['test_bar', 'test_foo'], sort(iced#system#all_requires('test_baz')))
" endfunction

function! s:suite.get_test() abort
  call s:setup()
  call s:assert.equals(0, s:count)
  call s:assert.equals({'name': 'foo', 'count': 0, 'this': {}}, iced#system#get('test_foo'))
  call s:assert.equals(1, s:count)
  call s:assert.equals({'name': 'foo', 'count': 0, 'this': {}}, iced#system#get('test_foo'))
  call s:assert.equals(1, s:count)
endfunction

function! s:suite.get_with_requires_test() abort
  call s:setup()
  call s:assert.equals(0, s:count)
  call s:assert.equals(
        \ {'name': 'baz', 'count': 2, 'this': {
        \  'test_bar': {'name': 'bar', 'count': 1, 'this': {
        \               'test_foo': {'name': 'foo', 'count': 0, 'this': {}}}}}},
        \ iced#system#get('test_baz'))
  call s:assert.equals(3, s:count)

  " update required component
  call iced#system#set_component('test_foo', {'start': {_ -> 'updated'}})
  call s:assert.equals(
       \ {'name': 'baz', 'count': 4, 'this': {
       \  'test_bar': {'name': 'bar', 'count': 3, 'this': {
       \               'test_foo': 'updated'}}}},
       \ iced#system#get('test_baz'))
  call s:assert.equals(5, s:count)
endfunction
