let s:suite  = themis#suite('iced.format')
let s:assert = themis#helper('assert')
let s:ch = themis#helper('iced_channel')
let s:buf = themis#helper('iced_buffer')

function! s:format_code_relay(msg, formatted) abort
  if a:msg['op'] ==# 'format-code-with-indents'
    return {'status': ['done'], 'formatted': a:formatted}
  elseif a:msg['op'] ==# 'set-indentation-rules'
    return {'status': ['done']}
  elseif a:msg['op'] ==# 'ns-aliases'
    return {'status': ['done'], 'aliases': {}}
  else
    return {}
  endif
endfunction

function! s:suite.form_test() abort
  call s:buf.start_dummy([
        \ '(list :foo)',
        \ '(list 123 456|)',
        \ ])
  call s:ch.inject_dummy({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:format_code_relay(msg, ':dummy-formatted')}})

  call iced#format#form()
  call s:assert.equals(s:buf.get_texts(),
        \ "(list :foo)\n:dummy-formatted")

  call s:buf.stop_dummy()
endfunction
