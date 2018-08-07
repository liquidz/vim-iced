let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#cider#sync#complete(base, context) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return v:none
  endif

  let msg = {
        \ 'op': 'complete',
        \ 'session': iced#nrepl#current_session(),
        \ 'symbol': a:base,
        \ 'extra-metadata': ['arglists', 'doc'],
        \ }

  if !empty(a:context)
    let msg['context'] = a:context
  endif

  return iced#nrepl#sync#send(msg)
endfunction

function! iced#nrepl#cider#sync#ns_list() abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return v:none
  endif

  return iced#nrepl#sync#send({
      \ 'op': 'ns-list',
      \ 'session': iced#nrepl#current_session(),
      \ })
endfunction

function! iced#nrepl#cider#sync#ns_vars(ns) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return v:none
  endif

  return iced#nrepl#sync#send({
      \ 'op': 'ns-vars-with-meta',
      \ 'session': iced#nrepl#current_session(),
      \ 'ns': a:ns,
      \ })
endfunction

function! iced#nrepl#cider#sync#ns_path(ns) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return v:none
  endif

  return iced#nrepl#sync#send({
      \ 'op': 'ns-path',
      \ 'session': iced#nrepl#current_session(),
      \ 'ns': a:ns,
      \ })
endfunction

call iced#nrepl#register_handler('complete')
call iced#nrepl#register_handler('ns-list')
call iced#nrepl#register_handler('ns-vars-with-meta')
call iced#nrepl#register_handler('ns-path')

let &cpo = s:save_cpo
unlet s:save_cpo
