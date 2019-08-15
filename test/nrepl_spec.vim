let s:suite  = themis#suite('iced.nrepl.spec')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:ch = themis#helper('iced_channel')
let s:sel = themis#helper('iced_selector')
let s:funcs = s:scope.funcs('autoload/iced/nrepl/spec.vim')

let s:cat_sample = [
      \ 'clojure.spec.alpha/cat',
      \   ':bindings',
      \     ':clojure.core.specs.alpha/bindings',
      \   ':body',
      \     ['clojure.spec.alpha/*', 'clojure.core/any?'],
      \ ]

let s:cat_once_sample = [
      \ 'clojure.spec.alpha/cat', ':foo', '::bar']

" iced#nrepl#spec#format {{{
function! s:suite.format_cat_test() abort
  call s:assert.equals(iced#nrepl#spec#format(s:cat_sample),
        \ join([
        \   '(s/cat',
        \   '  :bindings :clojure.core.specs.alpha/bindings',
        \   '  :body (s/* any?))',
        \ ], "\n"))

  call s:assert.equals(iced#nrepl#spec#format(s:cat_once_sample),
        \ '(s/cat :foo ::bar)')
endfunction

let s:or_sample = [
      \ 'clojure.spec.alpha/cat',
      \   ':foo',
      \     ['clojure.spec.alpha/or',
      \       ':string', 'clojure.core/string?',
      \       ':none', 'clojure.core/nil?',
      \     ],
      \ ]

function! s:suite.format_or_test() abort
  call s:assert.equals(iced#nrepl#spec#format(s:or_sample),
        \ join([
        \   '(s/cat',
        \   '  :foo (s/or',
        \   '         :string string?',
        \   '         :none nil?))',
        \ ], "\n"))
endfunction

let s:keys_sample = [
      \ 'clojure.spec.alpha/keys',
      \   ':req-un', ['::foo.core/bar', '::bar.core/baz'],
      \   ':opt-un', ['::baz.core/foo'],
      \ ]

let s:keys_once_sample = [
      \ 'clojure.spec.alpha/keys',
      \   ':req-un', ['::foo.core/bar'],
      \ ]

function! s:suite.format_keys_test() abort
  call s:assert.equals(iced#nrepl#spec#format(s:keys_sample),
        \ join([
        \   '(s/keys',
        \   '  :req-un [::foo.core/bar ::bar.core/baz]',
        \   '  :opt-un [::baz.core/foo])',
        \ ], "\n"))

  call s:assert.equals(iced#nrepl#spec#format(s:keys_once_sample),
        \ '(s/keys :req-un [::foo.core/bar])')
endfunction

let s:fspec_sample = [
      \ 'clojure.spec.alpha/fspec',
      \   ':args', [
      \     'clojure.spec.alpha/cat',
      \       ':foo',
      \         ['clojure.spec.alpha/or', ':str', 'string?', ':none', 'nil?'],
      \   ],
      \   ':ret', 'any?'
      \ ]

function! s:suite.format_fspec_test() abort
  call s:assert.equals(iced#nrepl#spec#format(s:fspec_sample),
        \ join([
        \   '(s/fspec',
        \   '  :args (s/cat',
        \   '          :foo (s/or',
        \   '                 :str string?',
        \   '                 :none nil?))',
        \   '  :ret any?)',
        \ ], "\n"))
endfunction
" }}}

" iced#nrepl#spec#form {{{
function! s:form_relay(msg) abort
  let op = a:msg['op']
  if op ==# 'eval'
    return {'status': ['done'], 'value': a:msg['code']}
  elseif op ==# 'spec-form'
    return {'status': ['done'], 'spec-form': s:cat_sample}
  endif
  return {'status': ['done']}
endfunction

function! s:suite.form_test() abort
  call s:ch.register_test_builder({'status_value': 'open', 'relay': funcref('s:form_relay')})
  call iced#buffer#document#init()

  try
    call iced#nrepl#spec#form(':dummy/spec')
    call iced#buffer#document#focus()
    let contents = getline(1, '$')
    call s:assert.equals(contents, [
          \ '(s/cat',
          \ '  :bindings :clojure.core.specs.alpha/bindings',
          \ '  :body (s/* any?))',
          \ ])
  finally
    silent exe ':q'
  endtry
endfunction
" }}}

" iced#nrepl#spec#list {{{
function! s:list_relay(msg) abort
  if a:msg['op'] ==# 'spec-list'
    return {'status': ['done'], 'spec-list': [':foo/bar', ':bar/baz']}
  endif
  return {'status': ['done']}
endfunction

function! s:suite.list_test() abort
  call s:ch.register_test_builder({'status_value': 'open', 'relay': funcref('s:list_relay')})
  call s:sel.register_test_builder()

  call iced#nrepl#spec#list()

  let config = s:sel.get_last_config()
  call s:assert.equals(sort(copy(config['candidates'])), [
        \ ':bar/baz',
        \ ':foo/bar'])
endfunction
" }}}

" iced#nrepl#spec#example {{{
function! s:example_relay(msg) abort
  let op = a:msg['op']
  if op ==# 'eval'
    return {'status': ['done'], 'value': a:msg['code']}
  elseif op ==# 'spec-example'
    return {'status': ['done'], 'spec-example': "\n\ndummy example\n\n"}
  endif
  return {'status': ['done']}
endfunction

function! s:suite.example_test() abort
  call s:ch.register_test_builder({'status_value': 'open', 'relay': funcref('s:example_relay')})
  call iced#buffer#document#init()

  try
    call iced#nrepl#spec#example(':dummy/spec')
    call iced#buffer#document#focus()
    let contents = getline(1, '$')
    call s:assert.equals(contents, ['dummy example'])
  finally
    silent exe ':q'
  endtry
endfunction
" }}}

" vim:fdm=marker:fdl=0
