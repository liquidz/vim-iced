let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:assoc(d, k, v) abort
  let d = copy(a:d)
  let d[a:k] = a:v
  return d
endfunction

function! iced#nrepl#sync#send(data) abort
  let [result, error] = iced#promise#wait(
        \ iced#promise#call(
        \   'iced#nrepl#send',
        \   {resolve -> [s:assoc(a:data, 'callback', resolve)]}))

  if error isnot# v:null
    if has_key(a:data, 'session')
      call iced#nrepl#interrupt(a:data.session)
    endif
    return iced#message#error('unexpected_error', string(error))
  endif

  return result
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

function! iced#nrepl#sync#eval(code, ...) abort
  let option = get(a:, 1, {})
  let session  = get(option, 'session_id', iced#nrepl#current_session())

  return iced#nrepl#sync#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'eval',
        \ 'code': a:code,
        \ 'session': session})
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
