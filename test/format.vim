let s:suite  = themis#suite('iced.format')
let s:assert = themis#helper('assert')
let s:ch = themis#helper('iced_channel')
let s:buf = themis#helper('iced_buffer')

function! GetClojureIndent() abort
  return -1
endfunction

function! s:format_code_relay(msg, formatted) abort
  if a:msg['op'] ==# 'iced-format-code-with-indents'
    return {'status': ['done'], 'formatted': a:formatted}
  elseif a:msg['op'] ==# 'iced-set-indentation-rules'
    return {'status': ['done']}
  elseif a:msg['op'] ==# 'ns-aliases'
    return {'status': ['done'], 'ns-aliases': {}}
  else
    return {'status': ['done']}
  endif
endfunction

function! s:suite.form_test() abort
  call s:buf.start_dummy([
        \ '(list :foo)',
        \ '(list 123 456|)',
        \ ])
  call s:ch.register_test_builder({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:format_code_relay(msg, ':dummy-formatted')}})

  call iced#format#form()
  call s:assert.equals(s:buf.get_texts(),
        \ "(list :foo)\n:dummy-formatted")

  call s:buf.stop_dummy()
endfunction

function! s:calculate_indent_relay(msg, level) abort
  if a:msg['op'] ==# 'iced-calculate-indent-level'
    return {'status': ['done'], 'indent-level': a:level}
  elseif a:msg['op'] ==# 'iced-set-indentation-rules'
    return {'status': ['done']}
  elseif a:msg['op'] ==# 'ns-aliases'
    return {'status': ['done'], 'ns-aliases': {}}
  else
    return {'status': ['done']}
  endif
endfunction

function! s:suite.calculate_indent_with_top_form_test() abort
  call s:ch.register_test_builder({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:calculate_indent_relay(msg, 1)}})
  call s:buf.start_dummy([
        \ '(foo',
        \ '|)',
        \ ])
  let result = iced#format#calculate_indent(line('.'))
  call s:assert.equals(result, 1)

  call s:buf.stop_dummy()
endfunction

function! s:suite.calculate_indent_with_nested_form_test() abort
  call s:ch.register_test_builder({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:calculate_indent_relay(msg, 2)}})
  call s:buf.start_dummy([
        \ '(foo',
        \ ' (bar',
        \ '  (baz',
        \ '|)))',
        \ ])
  let result = iced#format#calculate_indent(line('.'))
  call s:assert.equals(result, 2 + 1)

  call s:buf.stop_dummy()
endfunction

function! s:suite.calculate_indent_without_corresponding_form_test() abort
  call s:ch.register_test_builder({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:calculate_indent_relay(msg, 99)}})
  call s:buf.start_dummy([
        \ '(foo)',
        \ '|',
        \ ])
  let result = iced#format#calculate_indent(line('.'))
  call s:assert.equals(result, GetClojureIndent())

  call s:buf.stop_dummy()
endfunction
