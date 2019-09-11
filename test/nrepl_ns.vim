let s:suite  = themis#suite('iced.nrepl.ns')
let s:assert = themis#helper('assert')
let s:buf = themis#helper('iced_buffer')

function! s:suite.name_test() abort
  call s:buf.start_dummy(['(ns foo.bar)', '|'])
  call s:assert.equals(iced#nrepl#ns#name(), 'foo.bar')
  call s:buf.stop_dummy()

  call s:buf.start_dummy(['', '(ns', '  foo.bar', '  (:require [clojure.string :as str|])'])
  call s:assert.equals(iced#nrepl#ns#name(), 'foo.bar')
  call s:buf.stop_dummy()

  "" meta data
  call s:buf.start_dummy([
        \ ';; comment',
        \ '(ns ^{:me 1',
        \ '      :ta 2}',
        \ '  foo.bar)',
        \ '|',
        \ ])
  call s:assert.equals(iced#nrepl#ns#name(), 'foo.bar')
  call s:buf.stop_dummy()
endfunction

function! s:suite.name_with_tag_test() abort
  call s:buf.start_dummy(['(ns ^:tag foo.bar)', '|'])
  call s:assert.equals(iced#nrepl#ns#name(), 'foo.bar')
  call s:buf.stop_dummy()

  call s:buf.start_dummy(['(ns ^:tag', '  foo.bar)', '|'])
  call s:assert.equals(iced#nrepl#ns#name(), 'foo.bar')
  call s:buf.stop_dummy()
endfunction
