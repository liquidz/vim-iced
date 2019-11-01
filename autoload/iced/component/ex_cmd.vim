let s:save_cpo = &cpoptions
set cpoptions&vim

let s:ex_cmd = {}

function! s:ex_cmd.exe(str) abort
  exe a:str
endfunction

function! s:ex_cmd.silent_exe(str) abort
  silent exe a:str
endfunction

function! iced#component#ex_cmd#start(_) abort
  call iced#util#debug('start', 'ex_cmd')
  return s:ex_cmd
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
