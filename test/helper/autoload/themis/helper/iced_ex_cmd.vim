let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {'last_args': {}}

function! s:helper.exe(str) abort
  let self.last_args = {'exe': a:str}
endfunction

function! s:helper.silent_exe(str) abort
  let self.last_args = {'silent_exe': a:str}
endfunction

function! s:helper.mock() abort
  call iced#system#set_component('ex_cmd', {'constructor': {_ -> self}})
endfunction

function! s:helper.get_last_args() abort
  return self.last_args
endfunction

function! themis#helper#iced_ex_cmd#new(runner) abort
  return deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
