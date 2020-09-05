let s:suite  = themis#suite('iced.nrepl.ns')
let s:assert = themis#helper('assert')
let s:ch = themis#helper('iced_channel')
let s:buf = themis#helper('iced_buffer')
let s:holder = themis#helper('iced_holder')

function! s:suite.name_by_var_test() abort
  call s:ch.mock({
        \ 'status_value': 'open',
        \ 'relay': {_ -> {'status': ['done'], 'value': 'foo.bar1'}}})

  call s:assert.equals(iced#nrepl#ns#name_by_var(), 'foo.bar1')
endfunction

function! s:suite.name_by_buf_test() abort
  call s:buf.start_dummy(['(ns foo.bar2)', '|'])
  call s:assert.equals(iced#nrepl#ns#name_by_buf(), 'foo.bar2')
  call s:buf.stop_dummy()

  call s:buf.start_dummy(['', '(ns', '  foo.bar3', '  (:require [clojure.string :as str|])'])
  call s:assert.equals(iced#nrepl#ns#name_by_buf(), 'foo.bar3')
  call s:buf.stop_dummy()
endfunction

function! s:suite.name_by_buf_with_tag_test() abort
  call s:buf.start_dummy(['(ns ^:tag foo.bar4)', '|'])
  call s:assert.equals(iced#nrepl#ns#name_by_buf(), 'foo.bar4')
  call s:buf.stop_dummy()

  call s:buf.start_dummy(['(ns ^:tag', '  foo.bar5)', '|'])
  call s:assert.equals(iced#nrepl#ns#name_by_buf(), 'foo.bar5')
  call s:buf.stop_dummy()
endfunction

function! s:suite.name_by_buf_with_meta_test() abort
  call s:buf.start_dummy([
        \ ';; comment',
        \ '(ns ^{:me 1',
        \ '      :ta 2}',
        \ '  foo.bar6)',
        \ '|',
        \ ])
  call s:assert.equals(iced#nrepl#ns#name_by_buf(), 'foo.bar6')
  call s:buf.stop_dummy()
endfunction

function! s:suite.name_by_buf_without_ns_form_test() abort
  call s:buf.start_dummy(['(+ 1 2 3)', '|'])
  call s:assert.equals(iced#nrepl#ns#name_by_buf(), '')
  call s:buf.stop_dummy()
endfunction

function! s:suite.name_by_buf_in_ns_test() abort
  " c.f. https://github.com/clojure/clojure/blob/clojure-1.10.1/src/clj/clojure/core_print.clj#L9
  call s:buf.start_dummy(["(in-ns 'foo.bar7')", '|'])
  call s:assert.equals(iced#nrepl#ns#name_by_buf(), 'foo.bar7')
  call s:buf.stop_dummy()

  call s:buf.start_dummy(['(ns foo.bar8)', "(in-ns 'foo.barx')", '|'])
  call s:assert.equals(iced#nrepl#ns#name_by_buf(), 'foo.bar8')
  call s:buf.stop_dummy()

  call s:buf.start_dummy(["(in-ns 'foo.bar9')", '(ns foo.barx)', '|'])
  call s:assert.equals(iced#nrepl#ns#name_by_buf(), 'foo.bar9')
  call s:buf.stop_dummy()
endfunction

function! s:suite.name_test() abort
  call s:ch.mock({
        \ 'status_value': 'open',
        \ 'relay': {_ -> {'status': ['done'], 'value': 'foo.bar7'}}})

  call s:buf.start_dummy(['(ns foo.bar8)', '|'])
  call s:assert.equals(iced#nrepl#ns#name(), 'foo.bar8')
  call s:buf.stop_dummy()

  call s:buf.start_dummy(['|'])
  call s:assert.equals(iced#nrepl#ns#name(), 'foo.bar7')
  call s:buf.stop_dummy()
endfunction

function! s:__unalias_relay(msg) abort
  if a:msg['op'] ==# 'eval' && has_key(a:msg, 'code')
    call s:holder.run(a:msg['code'])
  endif
  return {'status': ['done']}
endfunction

function! s:suite.unalias_test() abort
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:__unalias_relay')})
  call s:buf.start_dummy(['(ns foo.core)', 'baz|'])

  call s:holder.clear()
  call iced#nrepl#ns#unalias('')
  call s:assert.equals(s:holder.get_args(), [['(ns-unalias ''foo.core ''baz)']])

  call s:holder.clear()
  call iced#nrepl#ns#unalias('sym')
  call s:assert.equals(s:holder.get_args(), [['(ns-unalias ''foo.core ''sym)']])

  call s:buf.stop_dummy()
endfunction
