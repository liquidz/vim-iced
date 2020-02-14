let s:suite  = themis#suite('iced.component.format.native-image')
let s:assert = themis#helper('assert')
let s:buf = themis#helper('iced_buffer')

let s:fmt = iced#system#get('format_cljstyle')

function! s:setup() abort
  call s:buf.start_dummy([
        \ '(ns foo.core',
        \ '    (:require [clojure.string :as str]',
        \ '    [clojure.set :as set]',
        \ '    ))',
        \ '',
        \ '(defn foo [bar]',
        \ '      (inc',
        \ '           |bar)',
        \ '      )', '', '', '',
        \ ])
endfunction

function! s:teardown() abort
  call s:buf.stop_dummy()
endfunction

function! s:suite.all_test() abort
  call s:setup()

  let p = s:fmt.all()
  call iced#promise#wait(p)
  call s:assert.equals(s:buf.get_lines(), [
        \ '(ns foo.core',
        \ '  (:require',
        \ '   [clojure.set :as set]',
        \ '   [clojure.string :as str]))',
        \ '',
        \ '(defn foo',
        \ '  [bar]',
        \ '  (inc',
        \ '   bar))',
        \ ])

  call s:teardown()
endfunction

function! s:suite.current_form_test() abort
  call s:setup()

  let p = s:fmt.current_form()
  call iced#promise#wait(p)

  call s:assert.equals(s:buf.get_lines(), [
        \ '(ns foo.core',
        \ '    (:require [clojure.string :as str]',
        \ '    [clojure.set :as set]',
        \ '    ))',
        \ '',
        \ '(defn foo',
        \ '  [bar]',
        \ '  (inc',
        \ '   bar))',
        \ '', '', '',
        \ ])

  call s:teardown()
endfunction

function! s:suite.minimal_test() abort
  call s:setup()

  call s:fmt.minimal({})
  call s:assert.equals(s:buf.get_lines(), [
        \ '(ns foo.core',
        \ '    (:require [clojure.string :as str]',
        \ '    [clojure.set :as set]',
        \ '    ))',
        \ '',
        \ '(defn foo [bar]',
        \ '      (inc',
        \ '       bar)',
        \ '      )', '', '', '',
        \ ])

  call s:teardown()
endfunction

function! s:suite.calculate_indent_test() abort
  call s:setup()

  let n = s:fmt.calculate_indent(getcurpos()[1])
  """ Expected
  "(defn foo
  "  [bar]
  "  (inc
  "   bar)) <== this indent level
  call s:assert.equals(n, 3)

  call s:teardown()
endfunction
