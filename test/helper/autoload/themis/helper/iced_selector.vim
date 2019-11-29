let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {}

function! s:helper.select(config) abort
  let self.last_config = a:config
endfunction

function! s:helper.mock() abort
  call iced#system#set_component('selector', {'start': {_ -> self}})
endfunction

function! s:helper.get_last_config() abort
  return self.last_config
endfunction

function! themis#helper#iced_selector#new(runner) abort
  return deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
