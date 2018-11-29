let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {}

function! s:helper.place(id, lnum, name, file) abort
  return ''
endfunction

function! s:helper.unplace(id) abort
  return ''
endfunction

function! s:helper.unplace_all() abort
  return ''
endfunction

function! s:helper.register_test_builder() abort
  call iced#di#register('sign', {_ -> self})
endfunction

function! themis#helper#iced_sign#new(runner) abort
  return  deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
