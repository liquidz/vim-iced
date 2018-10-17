let s:save_cpo = &cpo
set cpo&vim

function! iced#status() abort
  if !iced#nrepl#is_connected()
    return 'not connected'
  endif

  if iced#nrepl#is_evaluating()
    return 'evaluating'
  else
    return printf('%s repl', iced#nrepl#current_session_key())
  endif
endfunction

function! iced#eval_and_read(code, ...) abort
  let msg = {
      \ 'id': iced#nrepl#eval#id(),
      \ 'op': 'eval',
      \ 'code': a:code,
      \ 'session': iced#nrepl#current_session(),
      \ 'read-value': 'true',
      \ }
  let Callback = get(a:, 1, '')
  if iced#util#is_function(Callback)
    let msg['callback'] = Callback
    call iced#nrepl#send(msg)
  else
    return iced#nrepl#sync#send(msg)
  endif
endfunction

"" alias to ctrlp#iced#start
function! iced#select(config) abort
  return ctrlp#iced#start(a:config)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
