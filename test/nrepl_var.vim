let s:suite  = themis#suite('iced.nrepl.var')
let s:assert = themis#helper('assert')
let s:buf = themis#helper('iced_buffer')
let s:ch = themis#helper('iced_channel')

let s:test = {'result': {}}
function! s:test.callback(result) abort
  let self.result = a:result
endfunction

function! s:relay(msg) abort
  let op = a:msg['op']
  if op ==# 'info'
    return {'status': ['done'], 'msg': a:msg}
  elseif op ==# 'ns-aliases'
    return {'status': ['done'], 'ns-aliases': {'baz': 'baz.core'}}
  endif
  return {'status': ['done']}
endfunction

function! s:setup(...) abort
  let current_session = get(a:, 1, 'clj')
  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#nrepl#set_session('cljs',  'cljs-session')
  call iced#nrepl#change_current_session(current_session)

  call s:buf.start_dummy([
        \ '(ns foo.bar)',
        \ '(b|az)',
        \ ])
  call s:ch.register_test_builder({'status_value': 'open', 'relay': funcref('s:relay')})
endfunction

function! s:teardown() abort
  call iced#nrepl#set_session('clj',  '')
  call iced#nrepl#set_session('cljs',  '')
  call s:buf.stop_dummy()
endfunction

function! s:suite.get_test() abort
  call s:setup()
  call iced#nrepl#var#get({v -> s:test.callback(v)})
  call s:assert.equals(s:test.result['msg'], {
        \ 'session': 'clj-session',
        \ 'ns': 'foo.bar',
        \ 'symbol': 'baz',
        \ 'op': 'info'})
  call s:teardown()
endfunction

function! s:suite.get_with_specified_symbol_test() abort
  call s:setup()
  call iced#nrepl#var#get('baz/hello', {v -> s:test.callback(v)})
  call s:assert.equals(s:test.result['msg'], {
        \ 'session': 'clj-session',
        \ 'ns': 'foo.bar',
        \ 'symbol': 'baz/hello',
        \ 'op': 'info'})
  call s:teardown()
endfunction

function! s:suite.get_with_specified_emtpy_symbol_test() abort
  call s:setup()
  call iced#nrepl#var#get('', {v -> s:test.callback(v)})
  call s:assert.equals(s:test.result['msg'], {
        \ 'session': 'clj-session',
        \ 'ns': 'foo.bar',
        \ 'symbol': 'baz',
        \ 'op': 'info'})
  call s:teardown()
endfunction

function! s:suite.get_cljs_var_test() abort
  call s:setup('cljs')
  call iced#nrepl#var#get({v -> s:test.callback(v)})
  call s:assert.equals(s:test.result['msg'], {
       \ 'session': 'cljs-session',
       \ 'ns': 'foo.bar',
       \ 'symbol': 'baz',
       \ 'op': 'info'})
  call s:teardown()
endfunction

function! s:suite.get_cljs_specified_var_test() abort
  call s:setup('cljs')
  call iced#nrepl#var#get('baz/hello', {v -> s:test.callback(v)})
  call s:assert.equals(s:test.result['msg'], {
       \ 'session': 'cljs-session',
       \ 'ns': 'foo.bar',
       \ 'symbol': 'baz.core/hello',
       \ 'op': 'info'})
  call s:teardown()
endfunction

function! s:suite.get_cljs_keyword_test() abort
  call s:setup('cljs')
  call iced#nrepl#var#get(':baz/hello', {v -> s:test.callback(v)})
  call s:assert.equals(s:test.result['msg'], {
       \ 'session': 'cljs-session',
       \ 'ns': 'foo.bar',
       \ 'symbol': ':baz/hello',
       \ 'op': 'info'})
  call s:teardown()
endfunction
