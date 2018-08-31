let s:suite  = themis#suite('iced.nrepl.refactor.sync')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:funcs = s:scope.funcs('autoload/iced/nrepl/refactor/sync.vim')

function! s:suite.namespace_aliases_test() abort
  let dummy = '{:clj {foo (foo.core), bar (bar.core bar.bar)} :cljs {baz (baz.core)}}'
  let resp = {'status': ['done'], 'namespace-aliases': dummy}

  call s:assert.equals(
      \ s:funcs.namespace_aliases(resp),
      \ {'clj': {'foo': ['foo.core'], 'bar': ['bar.core', 'bar.bar']}, 'cljs': {'baz': ['baz.core']}})
endfunction
