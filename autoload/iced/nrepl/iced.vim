let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#iced#lint_ns(ns_name, linters, callback) abort
  if !iced#nrepl#is_connected() | return | endif

  let msg = {
      \ 'op': 'lint-ns',
      \ 'sesion': iced#nrepl#current_session(),
      \ 'ns': a:ns_name,
      \ 'callback': a:callback,
      \ }

  if !empty(a:linters) && type(a:linters) == type([])
    let msg['linters'] = a:linters
  endif

  call iced#nrepl#send(msg)
endfunction

function! iced#nrepl#iced#grimoire(platform, ns_name, symbol, callback) abort
  if !iced#nrepl#is_connected() | echom iced#message#get('not_connected') | return | endif

  call iced#nrepl#send({
        \ 'op': 'grimoire',
        \ 'sesion': iced#nrepl#current_session(),
        \ 'platform': a:platform,
        \ 'ns': a:ns_name,
        \ 'symbol': a:symbol,
        \ 'callback': a:callback,
        \ })
endfunction

call iced#nrepl#register_handler('lint-ns')
call iced#nrepl#register_handler('grimoire')

let &cpo = s:save_cpo
unlet s:save_cpo
