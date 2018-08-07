let s:save_cpo = &cpo
set cpo&vim

let g:iced#nrepl#cljs#custom#start_code = get(g:, 'iced#nrepl#cljs#custom#start_code', '')
let g:iced#nrepl#cljs#custom#stop_code = get(g:, 'iced#nrepl#cljs#custom#stop_code', '')

function! s:custom_start(callback) abort
  if !empty(g:iced#nrepl#cljs#custom#start_code)
    call iced#nrepl#send({
        \ 'id': iced#nrepl#eval#id(),
        \ 'op': 'eval',
        \ 'code': g:iced#nrepl#cljs#custom#start_code,
        \ 'session': iced#nrepl#repl_session(),
        \ 'callback': a:callback,
        \ })
  endif
endfunction

function! s:custom_stop() abort
  if !empty(g:iced#nrepl#cljs#custom#stop_code)
    call iced#nrepl#sync#send({
        \ 'id': iced#nrepl#eval#id(),
        \ 'op': 'eval',
        \ 'code': g:iced#nrepl#cljs#custom#stop_code,
        \ 'session': iced#nrepl#repl_session(),
        \ })
  endif
endfunction

function! iced#nrepl#cljs#custom#get_env() abort
  return {
      \ 'start': funcref('s:custom_start'),
      \ 'stop': funcref('s:custom_stop'),
      \ }
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
