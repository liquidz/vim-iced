let s:suite  = themis#suite('iced.nrepl')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:funcs = s:scope.funcs('autoload/iced/nrepl.vim')
let s:ch = themis#helper('iced_channel')

function! s:fixture() abort
  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#nrepl#set_session('cljs', 'cljs-session')
  call iced#nrepl#set_session('repl', 'repl-session')
endfunction

function! s:suite.set_clj_session_test() abort
  call s:fixture()
  call iced#nrepl#change_current_session('clj')
  call s:assert.equals(iced#nrepl#current_session(), 'clj-session')
endfunction

function! s:suite.set_cljs_session_test() abort
  call s:fixture()
  call iced#nrepl#change_current_session('cljs')
  call s:assert.equals(iced#nrepl#current_session(), 'cljs-session')
endfunction

function! s:suite.set_repl_session_test() abort
  call s:fixture()
  call s:assert.equals(iced#nrepl#repl_session(), 'repl-session')
endfunction

function! s:suite.set_invalid_session_test() abort
  try
    call iced#nrepl#set_session('invalid',  'session')
  catch
    call assert_exception('Invalid session-key to set:')
  endtry
endfunction

function! s:suite.change_to_invalid_session_test() abort
  try
    call s:fixture()
    call iced#nrepl#change_current_session('invalid')
  catch
    call assert_exception('Invalid session-key to change:')
  endtry
endfunction

function! s:suite.is_connected_test() abort
  call s:ch.inject_dummy({'status_value': 'open'})
  call s:assert.true(iced#nrepl#is_connected())

  call s:ch.inject_dummy({'status_value': 'fail'})
  call s:assert.false(iced#nrepl#is_connected())
endfunction

function! s:suite.connect_test() abort
  let test = {'session_patterns': ['foo-session', 'bar-session']}
  function! test.relay(msg) abort
    if a:msg['op'] ==# 'clone'
      return {'status': ['done'], 'new-session': remove(self.session_patterns, 0)}
    endif
    return {}
  endfunction

  call s:ch.inject_dummy({
      \ 'status_value': 'open',
      \ 'relay': {msg -> test.relay(msg)},
      \ })

  set nohidden
  call s:assert.equals(iced#nrepl#connect(1234), v:false)

  set hidden
  call s:assert.equals(iced#nrepl#connect(1234), v:true)
  call s:assert.equals(iced#nrepl#current_session_key(), 'clj')
  call s:assert.equals(iced#nrepl#repl_session(), 'foo-session')
  call s:assert.equals(iced#nrepl#current_session(), 'bar-session')
endfunction

function! s:suite.connect_failure_test() abort
  call s:ch.inject_dummy({'status_value': 'fail'})
  call s:assert.equals(iced#nrepl#connect(1234), v:false)
endfunction

function! s:suite.disconnect_test() abort
  let test = {'closed_sessions': []}
  function! test.relay(msg) abort
    let op = a:msg['op']
    if op ==# 'ls-sessions'
      return {'status': ['done'], 'sessions': ['foo-session', 'bar-session']}
    elseif op ==# 'close'
      call add(self.closed_sessions, a:msg['session'])
      return {'status': ['done']}
    endif
    return {}
  endfunction

  call s:ch.inject_dummy({
      \ 'status_value': 'open',
      \ 'relay': {msg -> test.relay(msg)},
      \ })

  call iced#nrepl#disconnect()
  call s:assert.equals(test.closed_sessions, ['foo-session', 'bar-session'])
endfunction

function! s:split_half(s) abort
  let l = len(a:s)
  let i = l / 2
  return [a:s[0:i], strpart(a:s, i+1)]
endfunction

function! s:suite.eval_test() abort
  let test = {}
  function! test.relay_raw(msg) abort
    if a:msg['op'] !=# 'eval' | return '' | endif

    let resp1 = iced#nrepl#bencode#encode({'id': 123, 'ns': 'foo.core', 'value': 6})
    let resp2 = iced#nrepl#bencode#encode({'id': 123, 'status': ['done']})
    return (s:split_half(resp1) + s:split_half(resp2))
  endfunction

  function! test.result_callback(result) abort
    let self['result'] = a:result
  endfunction

  call s:ch.inject_dummy({
      \ 'status_value': 'open',
      \ 'relay_raw': {msg -> test.relay_raw(msg)},
      \ })

  call iced#nrepl#eval(
      \ '(+ 1 2 3)',
      \ {result -> test.result_callback(result)},
      \ {'id': 123},
      \ )
  call s:assert.equals(test.result, {'status': ['done'], 'id': 123, 'ns': 'foo.core', 'value': 6})
endfunction
