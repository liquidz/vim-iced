let s:suite  = themis#suite('iced.nrepl.system')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:ch = themis#helper('iced_channel')
let s:funcs = s:scope.funcs('autoload/iced/nrepl/system.vim')

function! s:info_relay(msg, resp) abort
  if a:msg['op'] ==# 'eval'
    if type(a:resp) == v:t_dict
      let resp = copy(a:resp)
      if has_key(resp, 'classpath') | unlet resp['classpath'] | endif
      return {'status': ['done'], 'value': json_encode(resp)}
    else
      return {'status': ['done']}
    endif
  elseif a:msg['op'] ==# 'classpath'
    if type(a:resp) == v:t_dict && has_key(a:resp, 'classpath')
      return {'status': ['done'], 'classpath': a:resp['classpath']}
    else
      return {'status': ['done']}
    endif
  else
    return {}
  endif
endfunction

function! s:suite.info_test() abort
  let test_resp = {'user-dir': '/path/to/project'}
  call s:ch.register_test_builder({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:info_relay(msg, test_resp)}})

  call s:assert.equals(iced#nrepl#system#info(), test_resp)
endfunction

function! s:suite.info_error_test() abort
  call s:ch.register_test_builder({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:info_relay(msg, '')}})

  call s:assert.equals(iced#nrepl#system#info(), {})
endfunction

function! s:suite.user_dir_test() abort
  call iced#cache#clear()
  let test_resp = {'user-dir': '/path/to/project'}
  call s:ch.register_test_builder({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:info_relay(msg, test_resp)}})

  call s:assert.equals(iced#nrepl#system#user_dir(), '/path/to/project')
  call s:assert.equals(iced#cache#get('user-dir'), '/path/to/project')
endfunction

function! s:suite.user_dir_cached_test() abort
  call iced#cache#set('user-dir', '/foo/bar')
  let test_resp = {'user-dir': '/path/to/project'}
  call s:ch.register_test_builder({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:info_relay(msg, test_resp)}})

  call s:assert.equals(iced#nrepl#system#user_dir(), '/foo/bar')
  call s:assert.equals(iced#cache#get('user-dir'), '/foo/bar')
endfunction

function! s:suite.user_dir_error_test() abort
  call iced#cache#clear()
  call s:ch.register_test_builder({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:info_relay(msg, 'INVALID_RESPONSE')}})

  call s:assert.true(empty(iced#nrepl#system#user_dir()))
  call s:assert.false(iced#cache#has_key('user-dir'))
endfunction

function! s:suite.piggieback_enabled_falsy_test() abort
  call iced#cache#clear()

  let test_resp = {
        \ 'user-dir': '/path/to/project',
        \ 'classpath': ['/path/to/foo', '/path/to/bar'],
        \ }
  call s:ch.register_test_builder({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:info_relay(msg, test_resp)}})

  call s:assert.false(iced#nrepl#system#piggieback_enabled())
  call s:assert.false(iced#cache#has_key('piggieback-enabled?'))
endfunction

function! s:suite.piggieback_enabled_truthy_test() abort
  call iced#cache#clear()

  let test_resp = {
        \ 'user-dir': '/path/to/project',
        \ 'classpath': ['/path/to/foo', '/path/to/cider/piggieback', '/path/to/bar'],
        \ }
  call s:ch.register_test_builder({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:info_relay(msg, test_resp)}})

  call s:assert.true(iced#nrepl#system#piggieback_enabled())
  call s:assert.true(iced#cache#has_key('piggieback-enabled?'))
endfunction
