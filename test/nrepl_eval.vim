let s:suite  = themis#suite('iced.nrepl.eval')
let s:assert = themis#helper('assert')
let s:buf = themis#helper('iced_buffer')
let s:ch = themis#helper('iced_channel')
let s:qf = themis#helper('iced_quickfix')
let s:vt = themis#helper('iced_virtual_text')
let s:io = themis#helper('iced_io')
let s:holder = themis#helper('iced_holder')

let s:test_1_9_error =
      \ 'CompilerException java.lang.RuntimeException: Unable to resolve symbol: a in this context, compiling:(/path/to/src.clj:12:34)'

let s:test_1_10_error =
      \ "Syntax error compiling at (/path/to/src.clj:12:34).\nUnable to resolve symbol: a in this context"

" iced#nrepl#eval#err {{{
function! s:suite.err_with_1_9_or_above_test() abort
  call s:qf.mock()
  call s:qf.setlist([], 'r')
  call iced#nrepl#eval#err(s:test_1_9_error)
  call s:assert.equals(s:qf.get_last_args()['list'],
        \ [{'filename': '/path/to/src.clj',
        \   'lnum': '12',
        \   'text': 'CompilerException java.lang.RuntimeException: Unable to resolve symbol: a in this context'}])
endfunction

function! s:suite.err_with_1_10_or_later_test() abort
  call s:qf.mock()
  call s:qf.setlist([], 'r')
  call iced#nrepl#eval#err(s:test_1_10_error)
  call s:assert.equals(s:qf.get_last_args()['list'],
        \ [{'filename': '/path/to/src.clj',
        \   'lnum': '12',
        \   'text': 'Unable to resolve symbol: a in this context'}])
endfunction

function! s:suite.err_with_invalid_message_test() abort
  call s:qf.mock()
  call s:qf.setlist([], 'r')
  call iced#nrepl#eval#err('invalid message')
  call s:assert.true(empty(s:qf.get_last_args()['list']))
endfunction
" }}}

" iced#nrepl#eval#code {{{
let s:last_evaluated_code = ''
function! s:code_relay(msg) abort
  if a:msg['op'] ==# 'eval'
    let s:last_evaluated_code = a:msg['code']
  endif
  return {'status': ['done'], 'value': '123'}
endfunction

function! s:suite.code_test() abort
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:code_relay')})
  call s:vt.mock()

  let g:iced#eval#inside_comment = v:false
  let p =  iced#nrepl#eval#code('(comment (+ 1 2 3))')
  call iced#promise#wait(p)

  call s:assert.equals(s:last_evaluated_code, '(comment (+ 1 2 3))')
  let last_args = get(s:vt.get_last_args(), 'set', {})
  call s:assert.equals(last_args['text'], '=> 123')

  let g:iced#eval#inside_comment = v:true
  let p =  iced#nrepl#eval#code('(comment (+ 1 2 3))')
  call iced#promise#wait(p)

  call s:assert.equals(s:last_evaluated_code, '(+ 1 2 3)')
endfunction

function! s:suite.code_with_callback_test() abort
  let test = {'resp': ''}
  function! test.callback(resp) abort
    let self.resp = a:resp
  endfunction

  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:code_relay')})
  let p = iced#nrepl#eval#code('(+ 1 2 3)', {'callback': {v -> test.callback(v)}})
  call iced#promise#wait(p)

  call s:assert.equals(test.resp.status, ['done'])
endfunction
" }}}

" iced#nrepl#eval#undef {{{
function! s:undef_relay(msg) abort
  return {'status': ['done']}
endfunction

function! s:suite.undef_test() abort
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:undef_relay')})
  call s:io.mock()

  let sym = 'dummy/symbol'
  call iced#nrepl#eval#undef(sym)
  let last_arg = get(s:io.get_last_args(), 'echomsg', {})
  call s:assert.equals(last_arg['text'], iced#message#get('undefined', sym))
endfunction
" }}}

" iced#nrepl#eval#print_last {{{
function! s:print_last_relay(msg) abort
  if a:msg['op'] ==# 'eval' && a:msg['code'] ==# '*1'
    return {'status': ['done'], 'value': '"last result"'}
  endif
  return {'status': ['done']}
endfunction

function! s:suite.print_last_test() abort
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:print_last_relay')})
  call iced#buffer#stdout#init()

  try
    call iced#buffer#stdout#clear()
    call iced#nrepl#eval#print_last()
    call iced#buffer#stdout#open()
    call iced#buffer#stdout#focus()
    call s:assert.equals(getline('$'), '"last result"')
  finally
    silent exe ':q'
  endtry

endfunction
" }}}

" iced#nrepl#eval#outer_top_list {{{
function! s:suite.outer_top_list_test() abort
  call s:ch.mock({
        \ 'status_value': 'open',
        \ 'relay': {resp -> s:holder.relay(resp)},
        \ })
  call s:buf.start_dummy([
        \ '(foo)',
        \ '(bar',
        \ '  (hello',
        \ '    (world|)))',
        \ '(baz)',
        \ ])
  call s:holder.clear()

  let p = iced#nrepl#eval#outer_top_list()
  call iced#promise#wait(p)

  let msg = s:holder.get_args()[-1]
  call s:assert.equals(get(msg, 'code', ''), join([
        \ '(bar',
        \ '  (hello',
        \ '    (world)))',
        \ ], "\n"))

  call s:buf.stop_dummy()
endfunction
" }}}

" iced#nrepl#eval#ns {{{
function! s:suite.ns_test() abort
  call s:ch.mock({
        \ 'status_value': 'open',
        \ 'relay': {resp -> s:holder.relay(resp)},
        \ })
  call s:buf.start_dummy([
        \ '(ns foo',
        \ '  (:gen-class))',
        \ '',
        \ '(foo (bar|))',
        \ ])
  call s:holder.clear()

  let p = iced#nrepl#eval#ns()
  call iced#promise#wait(p)

  let msg = s:holder.get_args()[-1]
  call s:assert.equals(get(msg, 'code', ''), join([
        \ '(ns foo',
        \ '  (:gen-class))',
        \ ], "\n"))

  call s:buf.stop_dummy()
endfunction
" }}}

" iced#nrepl#eval#visual {{{
function! s:suite.visual_test() abort
  call s:ch.mock({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:holder.relay(msg)},
        \ })
  call s:buf.start_dummy(['(foo (bar|) (baz))'])
  call s:holder.clear()
  call iced#nrepl#change_current_session('clj')
  call iced#nrepl#set_session('clj',  'clj-session')

  silent exe "normal! vab\<Esc>"
  let p = iced#nrepl#eval#visual()
  call iced#promise#wait(p)

  let msg = s:holder.get_args()[-1]
  call s:assert.equals(get(msg, 'code', ''), '(bar)')
  call s:assert.equals(get(msg, 'session', ''), 'clj-session')

  call s:buf.stop_dummy()
endfunction
" }}}

" vim:fdm=marker:fdl=0
