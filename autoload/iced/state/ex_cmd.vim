let s:save_cpo = &cpo
set cpo&vim

let s:ex_cmd = {}

function! s:ex_cmd.exe(str) abort
  exe a:str
endfunction

function! s:ex_cmd.silent_exe(str) abort
  exe a:str
endfunction

function! iced#state#ex_cmd#definition() abort
  return {'start': {_ -> s:ex_cmd}}
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
