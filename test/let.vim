let s:suite  = themis#suite('iced.let')
let s:assert = themis#helper('assert')
let s:buf = themis#helper('iced_buffer')

function! s:suite.goto_test() abort
  call s:buf.start_dummy([
        \ '(let [foo 123]',
        \ '  (println foo)',
        \ '  |)',
        \ ])

  call s:assert.equals(line('.'), 3)
  call iced#let#goto()
  call s:assert.equals(line('.'), 1)
  call s:assert.equals(col('.'), 6)

  call s:buf.stop_dummy()

  call s:buf.start_dummy([
        \ '(let [foo 123]',
        \ '  (println foo)',
        \ '  (bar|))',
        \ ])

  call iced#let#goto()
  call s:assert.equals(line('.'), 1)
  call s:assert.equals(col('.'), 6)

  call s:buf.stop_dummy()
endfunction

function! s:suite.goto_no_let_test() abort
  call s:buf.start_dummy([
        \ '(list 123',
        \ '      456|)',
        \ ])

  let pos = getcurpos()
  call iced#let#goto()
  call s:assert.equals(getcurpos(), pos)

  call s:buf.stop_dummy()
endfunction

function! s:suite.goto_no_matched_let_test() abort
  call s:buf.start_dummy([
        \ '(do',
        \ '  (let [foo 123]',
        \ '    (println foo))',
        \ '  |foo)',
        \ ])

  let pos = getcurpos()
  call iced#let#goto()
  call s:assert.equals(getcurpos(), pos)

  call s:buf.stop_dummy()
endfunction

function! s:suite.move_to_let_test() abort
  call s:buf.start_dummy(['(let [a 1] (inc |a))'])
  call iced#let#move_to_let('b')
  call s:assert.equals(s:buf.get_texts(),
        \ "(let [a 1\n      b (inc a)] b)")
  call s:buf.stop_dummy()

  "" no let
  call s:buf.start_dummy(['(do (inc |a))'])
  call iced#let#move_to_let('b')
  call s:assert.equals(s:buf.get_texts(),
        \ "(do (let [b (inc a)]\n      b))")
  call s:buf.stop_dummy()

  "" no let in parent
  call s:buf.start_dummy([
        \ '(do (let [a 1] a)',
        \ '    (inc |a))',
        \ ])
  call iced#let#move_to_let('b')
  call s:assert.equals(s:buf.get_texts(),
        \ "(do (let [a 1] a)\n    (let [b (inc a)]\n      b))")
  call s:buf.stop_dummy()
endfunction

