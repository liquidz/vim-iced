let s:suite  = themis#suite('iced.nrepl.spec')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:funcs = s:scope.funcs('autoload/iced/nrepl/spec.vim')

let s:cat_sample = [
      \ 'clojure.spec.alpha/cat',
      \   ':bindings',
      \     ':clojure.core.specs.alpha/bindings',
      \   ':body',
      \     ['clojure.spec.alpha/*', 'clojure.core/any?'],
      \ ]

let s:or_sample = [
      \ 'clojure.spec.alpha/cat',
      \   ':foo',
      \     ['clojure.spec.alpha/or',
      \       ':string', 'clojure.core/string?',
      \       ':none', 'clojure.core/nil?',
      \     ],
      \ ]

let s:keys_sample = [
      \ 'clojure.spec.alpha/keys',
      \   ':req-un', ['::foo.core/bar', '::bar.core/baz'],
      \   ':opt-un', ['::baz.core/foo'],
      \ ]

function! s:suite.format_cat_test() abort
  call s:assert.equals(iced#nrepl#spec#format(s:cat_sample),
        \ join([
        \   '(s/cat',
        \   '  :bindings :clojure.core.specs.alpha/bindings',
        \   '  :body (s/* any?))',
        \ ], "\n"))
endfunction

function! s:suite.format_or_test() abort
  call s:assert.equals(iced#nrepl#spec#format(s:or_sample),
        \ join([
        \   '(s/cat',
        \   '  :foo (s/or :string string?',
        \   '             :none nil?))',
        \ ], "\n"))
endfunction

function! s:suite.format_keys_test() abort
  call s:assert.equals(iced#nrepl#spec#format(s:keys_sample),
        \ join([
        \   '(s/keys :req-un [::foo.core/bar ::bar.core/baz]',
        \   '        :opt-un [::baz.core/foo])',
        \ ], "\n"))
endfunction
