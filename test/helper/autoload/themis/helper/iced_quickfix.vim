let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {}

function! s:helper.setlist(list, action) abort
  let self.last_args = {'list': a:list, 'action': a:action}
endfunction

function! s:helper.setloclist(nr, list, action) abort
  let self.last_args = {'nr': a:nr, 'loclist': a:list, 'action': a:action}
endfunction

function! s:helper.mock() abort
  call iced#system#set_component('quickfix', {'constructor': {_ -> self}})
endfunction

function! s:helper.get_last_args() abort
  return self.last_args
endfunction

function! themis#helper#iced_quickfix#new(runner) abort
  return deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
