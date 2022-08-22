let s:suite  = themis#suite('iced.let')
let s:assert = themis#helper('assert')
let s:buf = themis#helper('iced_buffer')

function! s:suite.jump_to_let_test() abort
  call s:buf.start_dummy([
        \ '(let [foo 123]',
        \ '  (println foo)',
        \ '  |)',
        \ ])

  call s:assert.equals(line('.'), 3)
  call iced#let#jump_to_let()
  call s:assert.equals(line('.'), 1)
  call s:assert.equals(col('.'), 6)

  call s:buf.stop_dummy()

  call s:buf.start_dummy([
        \ '(let [foo 123]',
        \ '  (println foo)',
        \ '  (bar|))',
        \ ])

  call iced#let#jump_to_let()
  call s:assert.equals(line('.'), 1)
  call s:assert.equals(col('.'), 6)

  call s:buf.stop_dummy()
endfunction

function! s:suite.jump_to_let_no_let_test() abort
  call s:buf.start_dummy([
        \ '(list 123',
        \ '      456|)',
        \ ])

  let pos = getcurpos()
  call iced#let#jump_to_let()
  call s:assert.equals(getcurpos(), pos)

  call s:buf.stop_dummy()
endfunction

function! s:suite.jump_to_let_no_matched_let_test() abort
  call s:buf.start_dummy([
        \ '(do',
        \ '  (let [foo 123]',
        \ '    (println foo))',
        \ '  |foo)',
        \ ])

  let pos = getcurpos()
  call iced#let#jump_to_let()
  call s:assert.equals(getcurpos(), pos)

  call s:buf.stop_dummy()
endfunction
