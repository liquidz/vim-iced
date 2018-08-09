let s:suite  = themis#suite('iced.nrepl.ns.util')
let s:assert = themis#helper('assert')

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
