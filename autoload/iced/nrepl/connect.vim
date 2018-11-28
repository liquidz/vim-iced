let s:save_cpo = &cpo
set cpo&vim

let s:nrepl_port_file = '.nrepl-port'

function! s:detect_port_from_nrepl_port_file() abort
  let path = findfile(s:nrepl_port_file, '.;')
  return (empty(path)
        \ ? v:false
        \ : str2nr(readfile(path)[0]))
endfunction

function! s:detect_shadow_cljs_nrepl_port() abort
  let dot_shadow_cljs = finddir('.shadow-cljs', '.;')
  if empty(dot_shadow_cljs) | return v:false | endif

  let path = findfile('nrepl.port', dot_shadow_cljs)
  return (empty(path)
        \ ? v:false
        \ : str2nr(readfile(path)[0]))
endfunction

function! iced#nrepl#connect#auto() abort
  let port = s:detect_shadow_cljs_nrepl_port()
  if port
    call iced#nrepl#connect(port, 'cljs')
    return v:true
  endif

  let port = s:detect_port_from_nrepl_port_file()
  if port
    call iced#nrepl#connect(port)
    return v:true
  endif

  call iced#message#error('no_port_file')
  return v:false
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
