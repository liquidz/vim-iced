let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#op#refactor#clean_ns(callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let path = expand('%:p')
  call iced#nrepl#send({
      \ 'op': 'clean-ns',
      \ 'path': path,
      \ 'sesion': iced#nrepl#current_session(),
      \ 'callback': a:callback,
      \ })
endfunction

function! iced#nrepl#op#refactor#add_missing(symbol, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let symbol = empty(a:symbol) ? expand('<cword>') : a:symbol
  call iced#message#echom('resolving_missing')
  call iced#nrepl#send({
        \ 'op': 'resolve-missing',
        \ 'symbol': symbol,
        \ 'sesion': iced#nrepl#current_session(),
        \ 'callback': a:callback,
        \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
