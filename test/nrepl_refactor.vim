let s:suite = themis#suite('iced.nrepl.refactor')
let s:assert = themis#helper('assert')
let s:buf = themis#helper('iced_buffer')
let s:ch = themis#helper('iced_channel')

function! s:relay(msg) abort
  if a:msg['op'] ==# 'iced-format-code-with-indents'
    let code = substitute(a:msg['code'], '\s*\r\?\n\s\+', '\n', 'g')
    return {'status': ['done'], 'formatted': code}
  endif
  return {'status': ['done']}
endfunction

function! s:suite.add_arity_defn_test() abort
  call s:ch.register_test_builder({'status_value': 'open', 'relay': funcref('s:relay')})
  " Single arity
  call s:buf.start_dummy([
        \ '(ns foo.core)',
        \ '(defn foo [bar]',
        \ '  baz|)'])
  call iced#nrepl#refactor#add_arity()
  call s:assert.true(s:buf.test_curpos([
        \ '(ns foo.core)',
        \ '(defn foo',
        \ '      ([|])',
        \ '      ([bar]',
        \ '      baz))']))
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
        \ '       ([|])',
        \ '       ([bar]',
        \ '       baz))']))
  call s:buf.stop_dummy()
endfunction

function! s:suite.add_arity_with_doc_string_test() abort
  call s:ch.register_test_builder({'status_value': 'open', 'relay': funcref('s:relay')})
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
        \ '      "doc-string"',
        \ '      ([|])',
        \ '      ([bar]',
        \ '      baz))']))
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
        \ '       "doc-string"',
        \ '       ([|])',
        \ '       ([bar]',
        \ '       baz))']))
  call s:buf.stop_dummy()
endfunction

function! s:suite.add_arity_with_meta_test() abort
  call s:ch.register_test_builder({'status_value': 'open', 'relay': funcref('s:relay')})
  " Single arity
  call s:buf.start_dummy([
        \ '(ns foo.core)',
        \ '(defn ^{:bar "baz"}',
        \ '  foo',
        \ '  "doc-string"',
        \ '  [bar]',
        \ '  baz|)'])
  call iced#nrepl#refactor#add_arity()
  call s:assert.true(s:buf.test_curpos([
        \ '(ns foo.core)',
        \ '(defn ^{:bar "baz"}',
        \ '      foo',
        \ '      "doc-string"',
        \ '      ([|])',
        \ '      ([bar]',
        \ '      baz))']))
  call s:buf.stop_dummy()

  " Multiple arity
  call s:buf.start_dummy([
        \ '(ns foo.core)',
        \ '(defn ^{:bar "baz"}',
        \ '  foo',
        \ '  "doc-string"',
        \ '  ([bar]',
        \ '   baz|))'])
  call iced#nrepl#refactor#add_arity()
  call s:assert.true(s:buf.test_curpos([
        \ '(ns foo.core)',
        \ '(defn ^{:bar "baz"}',
        \ '       foo',
        \ '       "doc-string"',
        \ '       ([|])',
        \ '       ([bar]',
        \ '       baz))']))
  call s:buf.stop_dummy()
endfunction

function! s:suite.add_arity_fn_test() abort
  call s:ch.register_test_builder({'status_value': 'open', 'relay': funcref('s:relay')})
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
        \ '             ([|])',
        \ '             ([bar] baz)))']))
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
        \ '               ([|])',
        \ '               ([bar] baz)))']))
  call s:buf.stop_dummy()
endfunction

function! s:suite.add_arity_defmacro_test() abort
  call s:ch.register_test_builder({'status_value': 'open', 'relay': funcref('s:relay')})
  " Single arity
  call s:buf.start_dummy([
        \ '(ns foo.core)',
        \ '(defmacro foo [bar]',
        \ '  `(baz|))'])
  call iced#nrepl#refactor#add_arity()
  call s:assert.true(s:buf.test_curpos([
        \ '(ns foo.core)',
        \ '(defmacro foo',
        \ '         ([|])',
        \ '         ([bar]',
        \ '         `(baz)))']))
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
        \ '          ([|])',
        \ '          ([bar]',
        \ '          `(baz)))']))
  call s:buf.stop_dummy()
endfunction

function! s:suite.add_arity_defmethod_test() abort
  call s:ch.register_test_builder({'status_value': 'open', 'relay': funcref('s:relay')})
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
        \ '        ([|])',
        \ '        ([baz]',
        \ '        hello))']))
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
        \ '         ([|])',
        \ '         ([baz]',
        \ '         hello))']))
  call s:buf.stop_dummy()
endfunction

" call s:assert.equals('foo', s:buf.get_texts())
