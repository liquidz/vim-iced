let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#op#cider#sync#complete(base, ns_name, context) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return v:none
  endif

  let msg = {
        \ 'op': 'complete',
        \ 'session': iced#nrepl#current_session(),
        \ 'ns': a:ns_name,
        \ 'symbol': a:base,
        \ 'extra-metadata': ['arglists', 'doc'],
        \ }

  if !empty(a:context)
    let msg['context'] = a:context
  endif

  return iced#nrepl#sync#send(msg)
endfunction

function! iced#nrepl#op#cider#sync#ns_list() abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return v:none
  endif

  return iced#nrepl#sync#send({
      \ 'op': 'ns-list',
      \ 'session': iced#nrepl#current_session(),
      \ })
endfunction

function! iced#nrepl#op#cider#sync#ns_vars(ns) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return v:none
  endif

  return iced#nrepl#sync#send({
      \ 'op': 'ns-vars-with-meta',
      \ 'session': iced#nrepl#current_session(),
      \ 'ns': a:ns,
      \ 'verbose': v:false,
      \ })
endfunction

function! iced#nrepl#op#cider#sync#ns_path(ns) abort
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

let &cpo = s:save_cpo
unlet s:save_cpo
