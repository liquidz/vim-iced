let s:save_cpo = &cpoptions
set cpoptions&vim

let s:sync_resp = ''
let s:default_timeout_ms = 3000

let g:iced#nrepl#sync#timeout_ms = get(g:, 'iced#nrepl#sync#timeout_ms', s:default_timeout_ms)

function! s:sync(resp) abort
  let s:sync_resp = a:resp
endfunction

function! iced#nrepl#sync#send(data) abort
  let data = copy(a:data)
  let data.callback = funcref('s:sync')
  let s:sync_resp = ''

  call iced#nrepl#send(data)
  if !iced#util#wait({-> empty(s:sync_resp)}, g:iced#nrepl#sync#timeout_ms)
    " timeout
    if has_key(data, 'session')
      call iced#nrepl#interrupt(data['session'])
    endif
    call iced#message#error('timeout')
  endif

  return s:sync_resp
endfunction

function! iced#nrepl#sync#clone(session) abort
  let resp = iced#nrepl#sync#send({
      \ 'op': 'clone',
      \ 'session': a:session
      \ })
  return get(resp, 'new-session', '')
endfunction

function! iced#nrepl#sync#close(session) abort
  return iced#nrepl#sync#send({
      \ 'op': 'close',
      \ 'session': a:session
      \ })
endfunction

function! iced#nrepl#sync#session_list() abort
  let resp = iced#nrepl#sync#send({'op': 'ls-sessions'})
  if empty(resp)
    return []
  endif

  return get(resp, 'sessions', [])
endfunction

function! iced#nrepl#sync#pprint(code) abort
  let code = printf('(with-out-str (clojure.pprint/write ''%s :dispatch clojure.pprint/code-dispatch))', a:code)
  return iced#nrepl#sync#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'eval',
        \ 'code': code,
        \ 'session': iced#nrepl#clj_session(),
        \ })
endfunction

function! iced#nrepl#sync#eval(code, ...) abort
  let option = get(a:, 1, {})
  let session  = get(option, 'session_id', iced#nrepl#current_session())

  return iced#nrepl#sync#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'eval',
        \ 'code': a:code,
        \ 'session': session})
endfunction

function! iced#nrepl#sync#call(fn, args, ...) abort
  let resp = {'result': ''}
  function! resp.callback(v) abort
    let self.result = a:v
  endfunction

  let args = copy(a:args) + [{v -> resp.callback(v)}]
  call call(a:fn, args)
  if !iced#util#wait({-> empty(resp.result)}, g:iced#nrepl#sync#timeout_ms)
    let session = get(a:, 1, iced#nrepl#current_session())
    call iced#nrepl#interrupt(session)
    return iced#message#error('timeout')
  endif

  return copy(resp.result)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
