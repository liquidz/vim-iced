let s:suite  = themis#suite('iced.socket_repl.complete')
let s:assert = themis#helper('assert')
let s:ch = themis#helper('iced_socket_channel')
let s:holder = themis#helper('iced_holder')

function! s:suite.candidates_test() abort
  let g:vim_iced_home = expand('<sfile>:p:h')
  call s:holder.clear()
  call s:ch.mock({
        \ 'status_value': 'open',
        \ 'relay': {s -> (stridx(s, '__foo__') != -1 ? 'hello\nworld' : '')},
        \ })
  call iced#socket_repl#complete#candidates('__foo__', s:holder.run)

  call s:assert.equals(s:holder.get_args(), [[['hello', 'world']]])
endfunction
