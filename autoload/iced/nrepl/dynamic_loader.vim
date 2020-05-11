let s:save_cpo = &cpoptions
set cpoptions&vim

function! iced#nrepl#dynamic_loader#ls_middleware(callback) abort
  call iced#nrepl#send({
      \ 'op': 'ls-middleware',
      \ 'session': iced#nrepl#current_session(),
      \ 'callback': {resp -> a:callback(get(resp, 'middleware', [])) },
      \ })
endfunction

function! s:__add_middlewares(resp) abort
  if iced#util#has_status(a:resp, 'error')
    let resp = copy(a:resp)
    unlet resp['status']
    unlet resp['session']
    return iced#message#error(add_middleware_error, string(resp))
  endif
endfunction

function! iced#nrepl#dynamic_loader#add_middlewares(middleware_names) abort
  call iced#nrepl#send({
      \ 'op': 'add-middleware',
      \ 'session': iced#nrepl#current_session(),
      \ 'middleware': a:middleware_names,
      \ 'callback': funcref('s:__add_middlewares'),
      \ })
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
