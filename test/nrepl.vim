let s:suite  = themis#suite('iced.nrepl')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:funcs = s:scope.funcs('autoload/iced/nrepl.vim')

function! s:test_channel(opt) abort
  let dummy = {'env': 'test', 'status_value': 'fail'}
  call extend(dummy, a:opt)

  function! dummy.open(address, options) abort
    let self['address'] = a:address
    let self['options'] = a:options
    return self
  endfunction

  function! dummy.close(handle) abort
    return
  endfunction

  function! dummy.status(handle) abort
    return self.status_value
  endfunction

  function! dummy.sendraw(handle, string) abort
    if has_key(self, 'relay') && type(self.relay) == 2
      let sent_data = iced#nrepl#bencode#decode(a:string)
      let resp_data = iced#nrepl#bencode#encode(self.relay(sent_data))
      let Cb = (has_key(self, 'callback') && type(self.callback) == 2)
          \ ? self.callback : s:funcs.dispatcher
      call Cb(self, resp_data)
    else
      return
    endif
  endfunction

  return dummy
endfunction

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
  call iced#nrepl#inject_channel(s:test_channel({'status_value': 'open'}))
  call s:assert.true(iced#nrepl#is_connected())

  call iced#nrepl#inject_channel(s:test_channel({'status_value': 'fail'}))
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

  call iced#nrepl#inject_channel(s:test_channel({
      \ 'status_value': 'open',
      \ 'relay': {msg -> test.relay(msg)},
      \ }))
  call s:assert.equals(iced#nrepl#connect(1234), v:true)
  call s:assert.equals(iced#nrepl#current_session_key(), 'clj')
  call s:assert.equals(iced#nrepl#repl_session(), 'foo-session')
  call s:assert.equals(iced#nrepl#current_session(), 'bar-session')
endfunction

function! s:suite.connect_failure_test() abort
  call iced#nrepl#inject_channel(s:test_channel({'status_value': 'fail'}))
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

  call iced#nrepl#inject_channel(s:test_channel({
      \ 'status_value': 'open',
      \ 'relay': {msg -> test.relay(msg)},
      \ }))

  call iced#nrepl#disconnect()
  call s:assert.equals(test.closed_sessions, ['foo-session', 'bar-session'])
endfunction
