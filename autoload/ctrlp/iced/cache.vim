let s:save_cpo = &cpo
set cpo&vim

let s:dir = ctrlp#utils#cachedir()
      \ . ctrlp#utils#lash()
      \ . 'iced'

function! s:cachefile(name) abort
  return s:dir.ctrlp#utils#lash()
        \ . iced#nrepl#system#project_name()
        \ . '.' . a:name . '.txt'
endfunction

function! ctrlp#iced#cache#exists(name) abort
  return filereadable(s:cachefile(a:name))
endfunction

function! ctrlp#iced#cache#write(name, lines) abort
  let file = s:cachefile(a:name)
  call ctrlp#utils#writecache(a:lines, s:dir, file)
endfunction

function! ctrlp#iced#cache#read(name) abort
  if ctrlp#iced#cache#exists(a:name)
    let file = s:cachefile(a:name)
    return ctrlp#utils#readfile(file)
  else
    return []
  endif
endfunction

function! ctrlp#iced#cache#clear() abort
  for path in globpath(s:dir, '*.txt')
    call delete(path)
  endfor
  return iced#message#info('cache_cleared')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
