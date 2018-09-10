let s:suite  = themis#suite('iced.paredit')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:buf = themis#helper('iced_buffer')
let s:ch = themis#helper('iced_channel')
let s:funcs = s:scope.funcs('autoload/iced/nrepl.vim')

function! s:suite.deep_slurp_test() abort
  call s:ch.inject_dummy({
      \ 'status_value': 'open',
      \ 'relay': {msg -> (msg['op'] ==# 'format-code-with-indents' ?{'status': ['done'], 'formatted': msg['code']} : {})},
      \ })

  call s:buf.start_dummy(['(foo (|bar)) baz'])
  cal iced#paredit#deep_slurp()
  call s:assert.equals(s:buf.get_texts(), '(foo (bar) baz)')

  cal iced#paredit#deep_slurp()
  call s:assert.equals(s:buf.get_texts(), '(foo (bar baz))')

  call s:buf.stop_dummy()
endfunction

function! s:suite.barf_test() abort
  call s:buf.start_dummy(['(foo (|bar baz))'])

  cal iced#paredit#barf()
  call s:assert.equals(s:buf.get_texts(), '(foo (bar) baz)')

  call s:buf.stop_dummy()
endfunction

function! s:suite.get_current_top_list_test() abort
  call s:buf.start_dummy([
        \ '(foo',
        \ ' (bar|))',
        \ ])
  let res = iced#paredit#get_current_top_list()
  call s:assert.equals(res['code'], "(foo\n (bar))")
  call s:buf.stop_dummy()
endfunction

function! s:suite.get_current_top_list_with_blank_line_test() abort
  call s:buf.start_dummy([
        \ '(foo',
        \ '|',
        \ ' (bar))',
        \ ])
  let res = iced#paredit#get_current_top_list()
  call s:assert.equals(res['code'], "(foo\n\n (bar))")
  call s:buf.stop_dummy()
endfunction

function! s:suite.get_current_top_list_with_tag_test() abort
  call s:buf.start_dummy([
        \ '#?(:clj',
        \ '   (foo (bar|)))',
        \ ])
  let res = iced#paredit#get_current_top_list()
  call s:assert.equals(res['code'], "#?(:clj\n   (foo (bar)))")
  call s:buf.stop_dummy()
endfunction
