let s:suite  = themis#suite('iced.component.format.nrepl')
let s:assert = themis#helper('assert')
let s:ch = themis#helper('iced_channel')
let s:buf = themis#helper('iced_buffer')

let s:fmt = iced#system#get('format_default')

let g:iced_enable_clj_kondo_analysis = v:false
let g:iced_enable_clj_kondo_local_analysis = v:false
let g:iced_clj_kondo_analysis_dirs = []
let g:iced_cache_directory = ''

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

function! s:suite.all_test() abort
  call s:buf.start_dummy([
        \ '(list :foo)',
        \ '(list 123 456|)',
        \ '', '', '', '',
        \ ])
  call s:ch.mock({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:format_code_relay(msg, ":dummy\n:formatted")}})

  " set dummy marks
  call setpos("'a", [0, 1, 1, 0])
  call setpos("'b", [0, 2, 2, 0])
  call setpos("'<", [0, 2, 2, 0])
  call setpos("'<", [0, 1, 2, 0])
  call setpos("'>", [0, 1, 5, 0])

  let p = s:fmt.all()
  call iced#promise#wait(p)

  call s:assert.equals(s:buf.get_texts(),
        \ ":dummy\n:formatted")
  call s:assert.equals(getpos("'a"), [0, 1, 1, 0])
  call s:assert.equals(getpos("'b"), [0, 2, 2, 0])
  call s:assert.equals(getpos("'<"), [0, 1, 2, 0])
  call s:assert.equals(getpos("'>"), [0, 1, 5, 0])

  call s:buf.stop_dummy()
endfunction

function! s:suite.form_test() abort
  call s:buf.start_dummy([
        \ '(list :foo)',
        \ '(list 123 456|)',
        \ ])
  call s:ch.mock({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:format_code_relay(msg, ':dummy-formatted')}})

  " set dummy marks
  call setpos("'a", [0, 1, 1, 0])
  call setpos("'b", [0, 2, 2, 0])
  call setpos("'<", [0, 2, 2, 0])
  call setpos("'<", [0, 1, 2, 0])
  call setpos("'>", [0, 1, 5, 0])

  let p = s:fmt.current_form()
  call iced#promise#wait(p)

  call s:assert.equals(s:buf.get_texts(),
        \ "(list :foo)\n:dummy-formatted")
  call s:assert.equals(getpos("'a"), [0, 1, 1, 0])
  call s:assert.equals(getpos("'b"), [0, 2, 2, 0])
  call s:assert.equals(getpos("'<"), [0, 1, 2, 0])
  call s:assert.equals(getpos("'>"), [0, 1, 5, 0])

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
  call s:ch.mock({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:calculate_indent_relay(msg, 1)}})
  call s:buf.start_dummy([
        \ '(foo',
        \ '|)',
        \ ])
  let result = s:fmt.calculate_indent(line('.'))
  call s:assert.equals(result, 1)

  call s:buf.stop_dummy()
endfunction

function! s:suite.calculate_indent_with_nested_form_test() abort
  call s:ch.mock({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:calculate_indent_relay(msg, 3)}})
  call s:buf.start_dummy([
        \ '(foo',
        \ ' (bar',
        \ '  (baz',
        \ '|)))',
        \ ])
  let result = s:fmt.calculate_indent(line('.'))
  call s:assert.equals(result, 2 + 1)

  call s:buf.stop_dummy()
endfunction

function! s:suite.calculate_indent_without_corresponding_form_test() abort
  call s:ch.mock({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:calculate_indent_relay(msg, 99)}})
  call s:buf.start_dummy([
        \ '(foo)',
        \ '|',
        \ ])
  let result = s:fmt.calculate_indent(line('.'))
  call s:assert.equals(result, GetClojureIndent())

  call s:buf.stop_dummy()
endfunction
