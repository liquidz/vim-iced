let s:save_cpo = &cpo
set cpo&vim

function! s:show_source(resp) abort
  if !has_key(a:resp, 'out') || trim(a:resp['out']) ==# 'Source not found'
    call iced#message#error('not_found')
    return
  endif

  call iced#preview#view(a:resp['out'], 'clojure')
endfunction

function! iced#nrepl#source#show(symbol) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return
  endif

  let symbol = empty(a:symbol) ? expand('<cword>') : a:symbol
  let code = printf('(%s/source %s)', iced#nrepl#ns#repl(), symbol)
  call iced#nrepl#send({
      \ 'id': iced#nrepl#eval#id(),
      \ 'op': 'eval',
      \ 'code': code,
      \ 'session': iced#nrepl#repl_session(),
      \ 'verbose': v:false,
      \ 'callback': funcref('s:show_source'),
      \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
