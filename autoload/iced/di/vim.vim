let s:save_cpo = &cpo
set cpo&vim

let s:vim = {}

function! s:vim.exe(str) abort
  exe a:str
endfunction

function! iced#di#vim#build() abort
  return s:vim
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
