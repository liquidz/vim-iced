let s:suite  = themis#suite('iced.socket_repl.out')
let s:assert = themis#helper('assert')

function! s:suite.lines_test() abort
  call s:assert.equals(
        \ ['hello', 'world'],
        \ iced#socket_repl#out#lines({'out': '"hello\nworld"'}))
  call s:assert.equals(
        \ ['hello', 'world'],
        \ iced#socket_repl#out#lines({'value': '"hello\nworld"'}))
  call s:assert.equals(
        \ ['hello', 'world'],
        \ iced#socket_repl#out#lines({'out': "hello\r\nworld"}))

  call s:assert.equals(
        \ ['hello', 'world'],
        \ iced#socket_repl#out#lines({'out': "hello\r\nworld\nuser=> "}))
  call s:assert.equals(
        \ ['hello', 'world'],
        \ iced#socket_repl#out#lines({'out': "hello\r\nworld\nuser=> \n"}))
endfunction
