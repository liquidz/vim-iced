let s:suite  = themis#suite('iced.nrepl')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:funcs = s:scope.funcs('autoload/iced/nrepl.vim')
let s:ch = themis#helper('iced_channel')

function! s:fixture() abort
  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#nrepl#set_session('cljs', 'cljs-session')
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
  call s:ch.mock({'status_value': 'open'})
  call s:assert.true(iced#nrepl#is_connected())

  call s:ch.mock({'status_value': 'fail'})
  call s:assert.false(iced#nrepl#is_connected())
endfunction

function! s:suite.connect_test() abort
  let test = {'session_patterns': ['foo-session', 'dummy-session']}
  function! test.relay(msg) abort
    if a:msg['op'] ==# 'clone'
      return {'status': ['done'], 'new-session': remove(self.session_patterns, 0)}
    else
      return {'status': ['done']}
    endif
    return {}
  endfunction

  " # status_value
  "   1.fail means not connected yet
  "   2.fail means not connected by auto connection
  "   3.open means connection established
  call s:ch.mock({
      \ 'status_value': ['fail', 'fail', 'open'],
      \ 'relay': {msg -> test.relay(msg)},
      \ })

  call s:assert.equals(iced#nrepl#connect(1234), v:true)
  call s:assert.equals(iced#nrepl#current_session_key(), 'clj')
  call s:assert.equals(iced#nrepl#current_session(), 'foo-session')
endfunction

function! s:suite.connect_failure_test() abort
  call s:ch.mock({'status_value': 'fail'})
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
    return {'status': ['done']}
  endfunction

  call s:ch.mock({
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

    let resp1 = iced#system#get('bencode').encode({'id': 123, 'ns': 'foo.core', 'value': '6'})
    let resp2 = iced#system#get('bencode').encode({'id': 123, 'status': ['done']})
    return (s:split_half(resp1) + s:split_half(resp2))
  endfunction

  function! test.result_callback(result) abort
    let self['result'] = a:result
  endfunction

  call s:ch.mock({
      \ 'status_value': 'open',
      \ 'relay_raw': {msg -> test.relay_raw(msg)},
      \ })

  call iced#nrepl#eval(
      \ '(+ 1 2 3)',
      \ {'id': 123},
      \ {result -> test.result_callback(result)},
      \ )
  call s:assert.equals(test.result, {'status': ['done'], 'id': 123, 'ns': 'foo.core', 'value': '6'})
endfunction

function! s:suite.get_message_ids_test() abort
  call s:assert.equals([123], s:funcs.get_message_ids([{'id': 123}]))
  call s:assert.equals([123, 234], s:funcs.get_message_ids([{'id': 123}, {'id': 234}]))
  call s:assert.equals([123, 234], s:funcs.get_message_ids([{'id': 123}, {'id': 234}, {'id': 123}]))
  call s:assert.equals([-1], s:funcs.get_message_ids([{'foo': 'bar'}]))
  call s:assert.equals([-1, 123], s:funcs.get_message_ids([{'foo': 'bar'}, {'id': 123}]))
endfunction

function! s:suite.multiple_different_ids_response_test() abort
  let test = {}
  function! test.relay_raw(msg) abort
    if a:msg['op'] !=# 'eval' | return '' | endif
    let resp1 = iced#system#get('bencode').encode({'id': 123, 'ns': 'foo.core', 'value': '6', 'status': ['done']})
    let resp2 = iced#system#get('bencode').encode({'id': 234, 'ns': 'bar.core', 'value': 'baaaarrrr', 'status': ['done']})
    return printf('%s%s', resp1, resp2)
  endfunction

  function! test.callback_for_123(result) abort
    let self['result123'] = a:result
  endfunction

  function! test.callback_for_234(result) abort
    let self['result234'] = a:result
  endfunction

  call s:ch.mock({'status_value': 'open', 'relay_raw': {msg -> test.relay_raw(msg)}})
  call s:funcs.set_message(234, {'op': 'eval', 'callback': test.callback_for_234})

  call iced#nrepl#eval('(+ 1 2 3)', {'id': 123}, {result -> test.callback_for_123(result)})
  call s:assert.equals(test.result123, {'status': ['done'], 'id': 123, 'ns': 'foo.core', 'value': '6'})
  call s:assert.equals(test.result234, {'status': ['done'], 'id': 234, 'ns': 'bar.core', 'value': 'baaaarrrr'})

  call s:funcs.clear_messages()
endfunction

function! s:suite.path_translation_handler_test() abort
  let g:iced#nrepl#path_translation = {}
  let resp = {'path': '/tmp/foo/bar', 'hello': '/tmp/world'}

  call s:assert.equals(
        \ iced#nrepl#path_translation_handler(['path'], resp, ''),
        \ resp,
        \ )

  let g:iced#nrepl#path_translation = {'/tmp': '/src'}
  call s:assert.equals(
        \ iced#nrepl#path_translation_handler(['path'], resp, ''),
        \ {'path': '/src/foo/bar', 'hello': '/tmp/world'},
        \ )

  let g:iced#nrepl#path_translation = {}
endfunction

function! s:suite.path_translation_handler_path_list_test() abort
  let g:iced#nrepl#path_translation = {}
  let resp = {'path': ['/tmp/foo', '/tmp/bar'], 'hello': '/tmp/world'}

  call s:assert.equals(
        \ iced#nrepl#path_translation_handler(['path'], resp, ''),
        \ resp,
        \ )

  let g:iced#nrepl#path_translation = {'/tmp': '/src'}
  call s:assert.equals(
        \ iced#nrepl#path_translation_handler(['path'], resp, ''),
        \ {'path': ['/src/foo', '/src/bar'], 'hello': '/tmp/world'},
        \ )

  let g:iced#nrepl#path_translation = {}
endfunction

function! s:suite.path_translation_handler_with_normalize_path_test() abort
  let g:iced#nrepl#path_translation = {}
  let resp = {'path': 'file:/tmp/foo/bar', 'hello': ['/tmp/world', 'jar:file:/tmp/world.jar!/tmp/file.clj']}

  call s:assert.equals(
        \ iced#nrepl#path_translation_handler(['path', 'hello'], resp, ''),
        \ {'path': '/tmp/foo/bar', 'hello': ['/tmp/world', 'zipfile:/tmp/world.jar::tmp/file.clj']},
        \ )

  let g:iced#nrepl#path_translation = {'/tmp': '/src'}
  call s:assert.equals(
        \ iced#nrepl#path_translation_handler(['path', 'hello'], resp, ''),
        \ {'path': '/src/foo/bar', 'hello': ['/src/world', 'zipfile:/src/world.jar::tmp/file.clj']},
        \ )

  let g:iced#nrepl#path_translation = {}
endfunction

function! s:suite.status_test() abort
  call s:ch.mock({'status_value': 'fail'})
  call s:assert.equals(iced#nrepl#status(), 'not connected')

  call s:ch.mock({'status_value': 'open'})
  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#nrepl#change_current_session('clj')
  call s:assert.equals(iced#nrepl#status(), 'CLJ')
endfunction

function! s:suite.status_with_cljs_session_test() abort
  call s:ch.mock({'status_value': 'open'})
  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#nrepl#set_session('cljs',  'cljs-session')
  call iced#nrepl#change_current_session('clj')
  call s:assert.equals(iced#nrepl#status(), 'CLJ(cljs)')
  call iced#nrepl#change_current_session('cljs')
  call s:assert.equals(iced#nrepl#status(), 'CLJS(clj)')
endfunction

function! s:suite.status_evaluating_test() abort
  let test = {}
  function! test.relay(msg) abort
    call s:assert.equals(iced#nrepl#status(), 'evaluating')
    return {'status': ['done']}
  endfunction

  call s:ch.mock({'status_value': 'open', 'relay': test.relay})
  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#eval_and_read('(+ 1 2 3)')
endfunction
