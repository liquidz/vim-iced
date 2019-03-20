let s:save_cpo = &cpo
set cpo&vim

let s:qf = {}

function! s:qf.setlist(list, action) abort
  silent call setqflist(a:list, a:action)
endfunction

function! iced#state#quickfix#start(_) abort
  return s:qf
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
