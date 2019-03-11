let s:save_cpo = &cpo
set cpo&vim

let s:ex_cmd = {}

function! s:ex_cmd.exe(str) abort
  exe a:str
endfunction

function! s:ex_cmd.silent_exe(str) abort
  exe a:str
endfunction

function! iced#di#ex_cmd#build(container) abort
  return s:ex_cmd
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
