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
  call iced#system#set_component('start_env_test', {
        \ 'start': {'vim': funcref('s:start_component', ['vim_start']),
        \           'neovim': funcref('s:start_component', ['neovim_start'])}})

  call iced#system#set_component('dummy1', {'start': funcref('s:start_component', ['dummy1'])})
  call iced#system#set_component('dummy2', {'start': funcref('s:start_component', ['dummy2'])})
  call iced#system#set_component('require_env_test', {
        \ 'start': funcref('s:start_component', ['baz']),
        \ 'requires': {'vim': ['dummy1'], 'neovim': ['dummy2']}})
endfunction

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
        \ {'name': 'bar', 'count': 1, 'this': {'test_foo': {'name': 'foo', 'count': 0, 'this': {}}}},
        \ iced#system#get('test_bar'))
  call s:assert.equals(2, s:count)

  " update required component
  call iced#system#set_component('test_foo', {'start': {_ -> 'updated'}})
  call s:assert.equals(
        \ {'name': 'bar', 'count': 2, 'this': {'test_foo': 'updated'}},
        \ iced#system#get('test_bar'))
  call s:assert.equals(3, s:count)
endfunction

function! s:suite.get_with_start_env_test() abort
  call s:setup()
  let name = has('nvim') ? 'neovim_start' : 'vim_start'

  call s:assert.equals(0, s:count)
  call s:assert.equals(
        \ {'name': name, 'this': {}, 'count': 0},
        \ iced#system#get('start_env_test'))
  call s:assert.equals(1, s:count)
endfunction

function! s:suite.get_with_require_env_test() abort
  call s:setup()
  "let name = has('nvim') ? 'dummy2' : 'dummy1'

  let expected_this = has('nvim')
        \ ? {'dummy2': {'name': 'dummy2', 'count': 0, 'this': {}}}
        \ : {'dummy1': {'name': 'dummy1', 'count': 0, 'this': {}}}

  call s:assert.equals(0, s:count)
  call s:assert.equals(
        \ {'name': 'baz', 'count': 1, 'this': expected_this},
        \ iced#system#get('require_env_test'))
  call s:assert.equals(2, s:count)
endfunction
