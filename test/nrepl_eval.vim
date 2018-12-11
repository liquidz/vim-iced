let s:suite  = themis#suite('iced.nrepl.eval')
let s:assert = themis#helper('assert')
let s:buf = themis#helper('iced_buffer')
let s:ch = themis#helper('iced_channel')
let s:qf = themis#helper('iced_quickfix')

let s:test_1_9_error =
      \ 'CompilerException java.lang.RuntimeException: Unable to resolve symbol: a in this context, compiling:(/path/to/src.clj:12:34)'

let s:test_1_10_error =
      \ "Syntax error compiling at (/path/to/src.clj:12:34).\nUnable to resolve symbol: a in this context"

function! s:suite.err_with_1_9_or_above_test() abort
  call s:qf.register_test_builder()
  call s:qf.setlist([], 'r')
  call iced#nrepl#eval#err(s:test_1_9_error)
  call s:assert.equals(s:qf.get_last_args()['list'],
        \ [{'filename': '/path/to/src.clj',
        \   'lnum': '12',
        \   'text': 'CompilerException java.lang.RuntimeException: Unable to resolve symbol: a in this context'}])
endfunction

function! s:suite.err_with_1_10_or_later_test() abort
  call s:qf.register_test_builder()
  call s:qf.setlist([], 'r')
  call iced#nrepl#eval#err(s:test_1_10_error)
  call s:assert.equals(s:qf.get_last_args()['list'],
        \ [{'filename': '/path/to/src.clj',
        \   'lnum': '12',
        \   'text': 'Unable to resolve symbol: a in this context'}])
endfunction

function! s:suite.err_with_invalid_message_test() abort
  call s:qf.register_test_builder()
  call s:qf.setlist([], 'r')
  call iced#nrepl#eval#err('invalid message')
  call s:assert.true(empty(s:qf.get_last_args()['list']))
endfunction

let s:last_evaluated_code = ''
function! s:code_relay(msg) abort
  if a:msg['op'] ==# 'eval'
    let s:last_evaluated_code = a:msg['code']
  endif
  return {'status': ['done']}
endfunction

function! s:suite.code_test() abort
  call s:ch.register_test_builder({'status_value': 'open', 'relay': funcref('s:code_relay')})

  let g:iced#eval#inside_comment = v:false
  call iced#nrepl#eval#code('(comment (+ 1 2 3))')
  call s:assert.equals(s:last_evaluated_code, '(comment (+ 1 2 3))')

  let g:iced#eval#inside_comment = v:true
  call iced#nrepl#eval#code('(comment (+ 1 2 3))')
  call s:assert.equals(s:last_evaluated_code, '(+ 1 2 3)')
endfunction
