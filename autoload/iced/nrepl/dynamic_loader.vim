let s:save_cpo = &cpoptions
set cpoptions&vim

function! iced#nrepl#dynamic_loader#ls_middleware(callback) abort
  " NOTE: remove the first two chars because middleware names start with "#'".
  call iced#nrepl#send({
      \ 'op': 'ls-middleware',
      \ 'session': iced#nrepl#current_session(),
      \ 'callback': {resp -> a:callback(map(get(resp, 'middleware', []),
      \                                     {_, v -> strpart(v, 2)})) },
      \ })
endfunction

function! s:__add_middlewares(names, resp) abort
  if iced#util#has_status(a:resp, 'error')
    let resp = copy(a:resp)
    unlet resp['status']
    unlet resp['session']
    call iced#message#error('load_middleware_error', s:names, string(resp))
    return v:false
  endif
  call iced#message#info('finish_to_load', a:names)
  return v:true
endfunction

function! iced#nrepl#dynamic_loader#add_middlewares(middleware_names, callback) abort
  call iced#nrepl#send({
      \ 'op': 'add-middleware',
      \ 'session': iced#nrepl#current_session(),
      \ 'middleware': a:middleware_names,
      \ 'callback': {resp -> a:callback(s:__add_middlewares(a:middleware_names, resp))},
      \ })
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
