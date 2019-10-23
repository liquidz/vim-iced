let s:save_cpo = &cpo
set cpo&vim

let s:qf = {}

function! s:qf.setlist(list, action) abort
  silent call setqflist(a:list, a:action)
endfunction

function! s:qf.setloclist(nr, list, action) abort
  silent call setloclist(a:nr, a:list, a:action)
endfunction

function! iced#di#quickfix#build(container) abort
  return s:qf
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
