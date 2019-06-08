let s:save_cpo = &cpoptions
set cpoptions&vim

let s:io = {}

function! s:io.input(prompt) abort
  return input(a:prompt)
endfunction

function! iced#di#io#build(container) abort
  return s:io
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
