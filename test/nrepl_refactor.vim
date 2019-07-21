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

function! s:suite.add_arity_single_test() abort
  call s:ch.register_test_builder({'status_value': 'open', 'relay': funcref('s:relay')})
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
endfunction

function! s:suite.add_arity_multi_test() abort
  call s:ch.register_test_builder({'status_value': 'open', 'relay': funcref('s:relay')})
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
