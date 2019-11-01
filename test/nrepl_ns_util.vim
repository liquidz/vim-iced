let s:suite  = themis#suite('iced.nrepl.ns.util')
let s:assert = themis#helper('assert')
let s:buf = themis#helper('iced_buffer')
let s:ch = themis#helper('iced_channel')

function! s:format_relay(msg) abort
  if a:msg['op'] ==# 'format-code-with-indents'
    return {'status': ['done'], 'formatted': a:msg['code']}
  elseif a:msg['op'] ==# 'eval'
    return {'status': ['done'], 'value': 'nil'}
  endif
  return {'status': ['done']}
endfunction

function! s:suite.replace_test() abort
  call s:buf.start_dummy([
        \ '(ns foo.core)',
        \ 'nil|'])
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:format_relay')})

  call s:assert.equals(line('.'), 2)
  call iced#nrepl#ns#util#replace("(ns bar.core\n  (:require clojure.string))")
  call s:assert.equals(s:buf.get_texts(),
        \ "(ns bar.core\n  (:require clojure.string))\nnil")
  call s:assert.equals(line('.'), 3)

  call s:buf.stop_dummy()
endfunction

function! s:suite.replace_ns_not_found_test() abort
  call s:buf.start_dummy(['(list :hello)', 'nil|'])
  let org_text = s:buf.get_texts()
  
  call s:assert.equals(line('.'), 2)
  call iced#nrepl#ns#util#replace('(ns bar.core)')
  call s:assert.equals(s:buf.get_texts(), org_text)
  call s:assert.equals(line('.'), 2)

  call s:buf.stop_dummy()
endfunction

function! s:suite.add_require_form_test() abort
  let res = iced#nrepl#ns#util#add_require_form('(ns foo.core)')
  call s:assert.equals(res, "(ns foo.core\n(:require))")

  let res = iced#nrepl#ns#util#add_require_form('(ns foo.core  (:require))')
  call s:assert.equals(res, '(ns foo.core  (:require))')
endfunction

function! s:suite.add_namespace_to_require_test() abort
  let code = '(ns foo.core (:require))'
  let res = iced#nrepl#ns#util#add_namespace_to_require(code, 'clojure.string', '')
  call s:assert.equals(res, '(ns foo.core (:require clojure.string))')

  let res = iced#nrepl#ns#util#add_namespace_to_require(code, 'clojure.string', 'str')
  call s:assert.equals(res, '(ns foo.core (:require [clojure.string :as str]))')
endfunction

function! s:suite.add_namespace_to_require_append_test1() abort
  let code = '(ns foo.core (:require clojure.set))'
  let res = iced#nrepl#ns#util#add_namespace_to_require(code, 'clojure.string', '')
  call s:assert.equals(res, "(ns foo.core (:require clojure.set\nclojure.string))")

  let res = iced#nrepl#ns#util#add_namespace_to_require(code, 'clojure.string', 'str')
  call s:assert.equals(res, "(ns foo.core (:require clojure.set\n[clojure.string :as str]))")
endfunction

function! s:suite.add_namespace_to_require_append_test2() abort
  let code = '(ns foo.core (:require [clojure.set :as set]))'
  let res = iced#nrepl#ns#util#add_namespace_to_require(code, 'clojure.string', '')
  call s:assert.equals(res, "(ns foo.core (:require [clojure.set :as set]\nclojure.string))")

  let res = iced#nrepl#ns#util#add_namespace_to_require(code, 'clojure.string', 'str')
  call s:assert.equals(res, "(ns foo.core (:require [clojure.set :as set]\n[clojure.string :as str]))")
endfunction

function! s:suite.add_namespace_to_require_ns_already_exists_test() abort
  let code = '(ns foo.core (:require [clojure.string :as str]))'
  let res = iced#nrepl#ns#util#add_namespace_to_require(code, 'clojure.string', '')
  call s:assert.equals(res, code)

  let res = iced#nrepl#ns#util#add_namespace_to_require(code, 'clojure.string', 'string')
  call s:assert.equals(res, code)
endfunction

function! s:suite.add_namespace_to_require_sub_ns_test() abort
  let code = '(ns foo.bar.baz (:require))'
  let res = iced#nrepl#ns#util#add_namespace_to_require(code, 'foo.bar', 'bar')
  call s:assert.equals(res, '(ns foo.bar.baz (:require [foo.bar :as bar]))')
endfunction

function! s:suite.add_test() abort
  call s:buf.start_dummy([
        \ '(ns foo.core)',
        \ 'nil|'])
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:format_relay')})

  call s:assert.equals(line('.'), 2)

  call iced#nrepl#ns#util#add('bar', '')
  call s:assert.equals(s:buf.get_texts(),
        \ "(ns foo.core\n(:require bar))\nnil")
  call s:assert.equals(line('.'), 3)

  call iced#nrepl#ns#util#add('baz', 'baz')
  call s:assert.equals(s:buf.get_texts(),
        \ "(ns foo.core\n(:require bar\nbaz))\nnil")
  call s:assert.equals(line('.'), 4)

  call iced#nrepl#ns#util#add('hello', 'world')
  call s:assert.equals(s:buf.get_texts(),
        \ "(ns foo.core\n(:require bar\nbaz\n[hello :as world]))\nnil")
  call s:assert.equals(line('.'), 5)

  call s:buf.stop_dummy()
endfunction

function! s:suite.extract_ns_test() abort
  call s:assert.equals(
      \ iced#nrepl#ns#util#extract_ns('#namespace[foo.bar]'),
      \ 'foo.bar')
  call s:assert.equals(
      \ iced#nrepl#ns#util#extract_ns('foo.bar'),
      \ 'foo.bar')
endfunction
