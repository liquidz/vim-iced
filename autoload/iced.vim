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

function! s:json_resp(resp) abort
  let resp = copy(a:resp)
  if has_key(resp, 'json')
    let resp['value'] = json_decode(a:resp['json'])
  endif
  return resp
endfunction

function! iced#eval_and_read(code, ...) abort
  let msg = {
      \ 'id': iced#nrepl#eval#id(),
      \ 'op': 'eval',
      \ 'code': a:code,
      \ 'session': iced#nrepl#current_session(),
      \ 'json': 'true',
      \ }
  let Callback = get(a:, 1, '')
  if iced#util#is_function(Callback)
    let msg['callback'] = {resp -> Callback(s:json_resp(resp))}
    call iced#nrepl#send(msg)
  else
    return s:json_resp(iced#nrepl#sync#send(msg))
  endif
endfunction

function! iced#selector(config) abort
  if globpath(&rtp, 'plugin/ctrlp.vim') !=# ''
    return ctrlp#iced#start(a:config)
  elseif globpath(&rtp, 'plugin/fzf.vim') !=# ''
    return fzf#iced#start(a:config)
  else
    return iced#message#error('no_selector')
  end
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
