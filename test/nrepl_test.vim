let s:suite  = themis#suite('iced.nrepl.test')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:funcs = s:scope.funcs('autoload/iced/nrepl/test.vim')

function! s:suite.get_test() abort
  call s:assert.equals(
      \ 'foo',
      \ s:funcs.error_message({'var': 'foo'}))

  call s:assert.equals(
      \ 'foo: bar',
      \ s:funcs.error_message({'var': 'foo', 'context': 'bar'}))
endfunction

