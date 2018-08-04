let s:save_cpo = &cpo
set cpo&vim

let s:nrepl_port_file = '.nrepl-port'

function! s:detect_port_from_nrepl_port_file() abort
  let path = findfile(s:nrepl_port_file, '.;')
  if empty(path)
    return v:false
  endif

  return str2nr(readfile(path)[0])
endfunction

function! iced#nrepl#connect#auto() abort
  let port = s:detect_port_from_nrepl_port_file()
  if port
    call iced#nrepl#connect(port)
    return v:true
  endif

  echom iced#message#get('no_port_file')
  return v:false
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
