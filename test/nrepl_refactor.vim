let s:suite = themis#suite('iced.nrepl.refactor')
let s:assert = themis#helper('assert')
let s:buf = themis#helper('iced_buffer')
let s:ch = themis#helper('iced_channel')
let s:io = themis#helper('iced_io')

let g:iced_enable_clj_kondo_analysis = v:false
let g:iced_cache_directory = ''

" extract_function {{{
function! s:extract_function_relay(locals, msg) abort
  if a:msg['op'] ==# 'find-used-locals'
    return {'status': ['done'], 'used-locals': a:locals}
  endif
  return {'status': ['done']}
endfunction

function! s:suite.extract_function_test() abort
  call s:ch.mock({'status_value': 'open', 'relay': function('s:extract_function_relay', [['a', 'b']])})
  call s:io.mock({'input': 'extracted'})
  call s:buf.start_dummy(['(foo (bar a b|))'])

  call iced#nrepl#refactor#extract_function()

  call s:assert.equals(s:buf.get_lines(), [
       \ '(defn- extracted [a b]',
       \ '  (bar a b))',
       \ '',
       \ '(foo (extracted a b))',
       \ ])

  call s:buf.stop_dummy()
endfunction

function! s:suite.extract_function_with_no_args_test() abort
  call s:ch.mock({'status_value': 'open', 'relay': function('s:extract_function_relay', [[]])})
  call s:io.mock({'input': 'extracted'})
  call s:buf.start_dummy(['(foo (bar|))'])

  call iced#nrepl#refactor#extract_function()

  call s:assert.equals(s:buf.get_lines(), [
       \ '(defn- extracted []',
       \ '  (bar))',
       \ '',
       \ '(foo (extracted))',
       \ ])

  call s:buf.stop_dummy()
endfunction
" }}}

" clean_ns {{{
function! s:clean_ns_relay(msg) abort
  if a:msg['op'] ==# 'clean-ns'
    return {'status': ['done'], 'ns': '(ns cleaned)'}
  endif
  return {'status': ['done']}
endfunction

function! s:suite.clean_ns_test() abort
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:clean_ns_relay')})
  call s:buf.start_dummy([
       \ '(ns foo.bar)',
       \ '(baz hello|)',
       \ ])

  let p = iced#nrepl#refactor#clean_ns()
  call iced#promise#wait(p)

  call s:assert.true(s:buf.test_curpos([
       \ '(ns cleaned)',
       \ '(baz hello|)',
       \ ]))

  call s:buf.stop_dummy()
endfunction
" }}}

" thread_first/last {{{
function! s:thread_relay(msg) abort
  if a:msg['op'] ==# 'iced-refactor-thread-first'
    return {'status': ['done'], 'code': '(thread first refactored)'}
  elseif a:msg['op'] ==# 'iced-refactor-thread-last'
    return {'status': ['done'], 'code': '(thread last refactored)'}
  endif
  return {'status': ['done']}
endfunction

function! s:suite.thread_first_test() abort
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:thread_relay')})
  call s:buf.start_dummy(['(foo (bar (baz 1) 2)|)'])
  call iced#nrepl#refactor#thread_first()
  call s:assert.equals(s:buf.get_texts(), '(thread first refactored)')
  call s:buf.stop_dummy()
endfunction

function! s:suite.thread_last_test() abort
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:thread_relay')})
  call s:buf.start_dummy(['(foo (bar (baz 1) 2)|)'])
  call iced#nrepl#refactor#thread_last()
  call s:assert.equals(s:buf.get_texts(), '(thread last refactored)')
  call s:buf.stop_dummy()
endfunction
" }}}

" add_arity {{{
function! s:add_arity_relay(msg) abort
  if a:msg['op'] ==# 'iced-format-code-with-indents'
    let code = substitute(a:msg['code'], '\s*\r\?\n\s\+', '\n', 'g')
    return {'status': ['done'], 'formatted': code}
  endif
  return {'status': ['done']}
endfunction

function! s:suite.add_arity_defn_test() abort
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:add_arity_relay')})
  " Single arity
  call s:buf.start_dummy([
       \ '(ns foo.core)',
       \ '(defn foo [bar]',
       \ '  baz|)'])
  call iced#nrepl#refactor#add_arity()
  call s:assert.true(s:buf.test_curpos([
      \ '(ns foo.core)',
      \ '(defn foo',
      \ '([|])',
      \ '([bar]',
      \ 'baz))']))
  call s:buf.stop_dummy()

  " Multiple arity
  call s:buf.start_dummy([
      \ '(ns foo.core)',
      \ '(defn foo',
      \ '  ([bar]',
      \ '   baz|))'])
  call iced#nrepl#refactor#add_arity()
  call s:assert.true(s:buf.test_curpos([
      \ '(ns foo.core)',
      \ '(defn foo',
      \ '([|])',
      \ '([bar]',
      \ 'baz))']))
  call s:buf.stop_dummy()
endfunction

function! s:suite.add_arity_with_doc_string_test() abort
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:add_arity_relay')})
  " Single arity
  call s:buf.start_dummy([
       \ '(ns foo.core)',
       \ '(defn foo',
       \ '  "doc-string"',
       \ '  [bar]',
       \ '  baz|)'])
  call iced#nrepl#refactor#add_arity()
  call s:assert.true(s:buf.test_curpos([
       \ '(ns foo.core)',
       \ '(defn foo',
       \ '"doc-string"',
       \ '([|])',
       \ '([bar]',
       \ 'baz))']))
  call s:buf.stop_dummy()

  " Multiple arity
  call s:buf.start_dummy([
       \ '(ns foo.core)',
       \ '(defn foo',
       \ '  "doc-string"',
       \ '  ([bar]',
       \ '   baz|))'])
  call iced#nrepl#refactor#add_arity()
  call s:assert.true(s:buf.test_curpos([
       \ '(ns foo.core)',
       \ '(defn foo',
       \ '"doc-string"',
       \ '([|])',
       \ '([bar]',
       \ 'baz))']))
  call s:buf.stop_dummy()
endfunction

function! s:suite.add_arity_with_meta_test() abort
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:add_arity_relay')})
  " Single arity
  call s:buf.start_dummy([
       \ '(ns foo.core)',
       \ '(defn ^{:bar "baz" :baz [1]}',
       \ '  foo',
       \ '  "doc-string"',
       \ '  [bar]',
       \ '  baz|)'])
  call iced#nrepl#refactor#add_arity()
  call s:assert.true(s:buf.test_curpos([
       \ '(ns foo.core)',
       \ '(defn ^{:bar "baz" :baz [1]}',
       \ 'foo',
       \ '"doc-string"',
       \ '([|])',
       \ '([bar]',
       \ 'baz))']))
  call s:buf.stop_dummy()

  " Multiple arity
  call s:buf.start_dummy([
       \ '(ns foo.core)',
       \ '(defn ^{:bar "baz" :baz [1]}',
       \ '  foo',
       \ '  "doc-string"',
       \ '  ([bar]',
       \ '   baz|))'])
  call iced#nrepl#refactor#add_arity()
  call s:assert.true(s:buf.test_curpos([
       \ '(ns foo.core)',
       \ '(defn ^{:bar "baz" :baz [1]}',
       \ 'foo',
       \ '"doc-string"',
       \ '([|])',
       \ '([bar]',
       \ 'baz))']))
  call s:buf.stop_dummy()
endfunction

function! s:suite.add_arity_fn_test() abort
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:add_arity_relay')})
  " Single arity
  call s:buf.start_dummy([
      \ '(ns foo.core)',
      \ '(def foo',
      \ '  (fn [bar] baz|))'])
  call iced#nrepl#refactor#add_arity()
  call s:assert.true(s:buf.test_curpos([
      \ '(ns foo.core)',
      \ '(def foo',
      \ '  (fn',
      \ '  ([|])',
      \ '  ([bar] baz)))']))
  call s:buf.stop_dummy()

  " Multiple arity
  call s:buf.start_dummy([
      \ '(ns foo.core)',
      \ '(def foo',
      \ '  (fn',
      \ '    ([bar] baz|)))',
      \ ])
  call iced#nrepl#refactor#add_arity()
  call s:assert.true(s:buf.test_curpos([
     \ '(ns foo.core)',
     \ '(def foo',
     \ '  (fn',
     \ '  ([|])',
     \ '  ([bar] baz)))']))
  call s:buf.stop_dummy()
endfunction

function! s:suite.add_arity_defmacro_test() abort
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:add_arity_relay')})
  " Single arity
  call s:buf.start_dummy([
       \ '(ns foo.core)',
       \ '(defmacro foo [bar]',
       \ '  `(baz|))'])
  call iced#nrepl#refactor#add_arity()
  call s:assert.true(s:buf.test_curpos([
       \ '(ns foo.core)',
       \ '(defmacro foo',
       \ '([|])',
       \ '([bar]',
       \ '`(baz)))']))
  call s:buf.stop_dummy()

  " Multiple arity
  call s:buf.start_dummy([
       \ '(ns foo.core)',
       \ '(defmacro foo',
       \ '  ([bar]',
       \ '   `(baz|)))'])
  call iced#nrepl#refactor#add_arity()
  call s:assert.true(s:buf.test_curpos([
       \ '(ns foo.core)',
       \ '(defmacro foo',
       \ '([|])',
       \ '([bar]',
       \ '`(baz)))']))
  call s:buf.stop_dummy()
endfunction

function! s:suite.add_arity_defmethod_test() abort
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:add_arity_relay')})
  " Single arity
  call s:buf.start_dummy([
       \ '(ns foo.core)',
       \ '(defmethod foo :bar',
       \ '  [baz]',
       \ '  hello|)'])
  call iced#nrepl#refactor#add_arity()
  call s:assert.true(s:buf.test_curpos([
       \ '(ns foo.core)',
       \ '(defmethod foo :bar',
       \ '([|])',
       \ '([baz]',
       \ 'hello))']))
  call s:buf.stop_dummy()

  " Multiple arity
  call s:buf.start_dummy([
       \ '(ns foo.core)',
       \ '(defmethod foo :bar',
       \ '  ([baz]',
       \ '   hello|))'])
  call iced#nrepl#refactor#add_arity()
  call s:assert.true(s:buf.test_curpos([
       \ '(ns foo.core)',
       \ '(defmethod foo :bar',
       \ '([|])',
       \ '([baz]',
       \ 'hello))']))
  call s:buf.stop_dummy()
endfunction
" }}}

function! s:dummy_info(name) abort
  return {
      \'ns': 'ns',
      \'name': a:name,
      \'file': 'file',
      \'line': 1,
      \'column': 1,
      \'status': ['done']}
endfunction

function! s:nrepl_mock(ops) abort
  call s:ch.mock({
      \'status_value': 'open',
      \'relay': {msg -> get(a:ops, msg['op'], {'status': ['done']})}})
endfunction

function! s:suite.rename_symbol_test() abort
  let def_file = tempname()
  call writefile([
      \'   (defn bar [] :bar)',
      \';; testing definition form not at column 1'],
      \def_file)

  let alias_file = tempname()
  call writefile([
      \'(ns a (:require [user :as a.u])',
      \'(let [bar (a.u/bar :bar))]',
      \';; testing symbol with namespace alias'],
      \alias_file)

  let refer_file = tempname()
  call writefile([
      \'(ns a (:require [user :refer [bar]])',
      \'(let [bar (bar :bar))]',
      \';; testing import using :refer'],
      \refer_file)

  let sameline_file = tempname()
  call writefile([
      \'[bar bar]',
      \';; testing 2 occurrences on the same line'],
      \sameline_file)

  let def_newline_file = tempname()
  call writefile([
      \'(def ^{:doc " bar "',
      \'       :optional 123}',
      \' bar)',
      \';; testing definition form with metadata'],
      \def_newline_file)

  call s:nrepl_mock({
      \'info': s:dummy_info('bar'),
      \'find-symbol': [
      \  {'occurrence': '{:file "'.def_file.'"   :line-beg 1 :col-beg 4}'},
      \  {'occurrence': '{:file "'.alias_file.'" :line-beg 2 :col-beg 12}'},
      \  {'occurrence': '{:file "'.refer_file.'" :line-beg 1 :col-beg 31}'},
      \  {'occurrence': '{:file "'.refer_file.'" :line-beg 2 :col-beg 12}'},
      \  {'occurrence': '{:file "'.sameline_file.'" :line-beg 1 :col-beg 2}'},
      \  {'occurrence': '{:file "'.sameline_file.'" :line-beg 1 :col-beg 6}'},
      \  {'occurrence': '{:file "'.def_newline_file.'" :line-beg 1 :col-beg 1}'},
      \  {'status': ['done']}]})


  call iced#system#reset_component('job')
  call iced#system#reset_component('edn')
  call iced#system#reset_component('ex_cmd')
  call s:io.mock({'input': 'new-name'})
  call iced#promise#wait(iced#nrepl#refactor#rename_symbol('dummy'))


  call s:assert.equals(readfile(def_file), [
      \'   (defn new-name [] :bar)',
      \';; testing definition form not at column 1'
      \])
  call delete(def_file)

  call s:assert.equals(readfile(alias_file), [
      \'(ns a (:require [user :as a.u])',
      \'(let [bar (a.u/new-name :bar))]',
      \';; testing symbol with namespace alias'
      \])
  call delete(alias_file)

  call s:assert.equals(readfile(refer_file), [
      \'(ns a (:require [user :refer [new-name]])',
      \'(let [bar (new-name :bar))]',
      \';; testing import using :refer'])
  call delete(refer_file)

  call s:assert.equals(readfile(sameline_file), [
      \'[new-name new-name]',
      \';; testing 2 occurrences on the same line'])
  call delete(sameline_file)

  call s:assert.equals(readfile(def_newline_file), [
      \'(def ^{:doc " bar "',
      \'       :optional 123}',
      \' new-name)',
      \';; testing definition form with metadata'])
  call delete(def_newline_file)

  call themis#log('FIXME file %s', expand('%:p'))
  execute printf(':cd %s', expand('<sfile>:p:h'))
endfunction

function! s:suite.rename_symbol_no_user_input_test() abort
  let def_file = tempname()
  let original_src = ['(ns user)', '   (defn bar [] :bar)']
  call writefile(original_src, def_file)

  call s:nrepl_mock({
      \'info': s:dummy_info('bar'),
      \'find-symbol': [
      \  {'occurrence': '{:file "'.def_file.'"   :line-beg 2 :col-beg 4}'},
      \  {'status': ['done']}]})


  call s:io.mock({'input': ' '})
  call iced#promise#wait(iced#nrepl#refactor#rename_symbol('dummy'))


  call s:assert.equals(readfile(def_file), original_src)
  call delete(def_file)

  call s:assert.equals(
      \ s:io.get_last_args()['echomsg']['text'],
      \ iced#message#get('canceled'),
      \ )
endfunction

function! s:suite.rename_symbol_not_found_test() abort
  call s:nrepl_mock({'info': {'status': ['done', 'no-info']}})
  call s:io.mock()

  call iced#promise#wait(iced#nrepl#refactor#rename_symbol('dummy'))

  call s:assert.equals(
      \ s:io.get_last_args()['echomsg']['text'],
      \ iced#message#get('not_found'),
      \ )
endfunction

function! s:suite.rename_symbol_in_jar_test() abort
  let info = s:dummy_info('bar')
  let info.file = 'zipfile:/path/to.jar::some/namespace.clj'
  call s:nrepl_mock({'info': info})
  call s:io.mock()

  call iced#promise#wait(iced#nrepl#refactor#rename_symbol('dummy'))

  call s:assert.equals(
      \ s:io.get_last_args()['echomsg']['text'],
      \ iced#message#get('not_found'),
      \ )
endfunction

" vim:fdm=marker:fdl=0
