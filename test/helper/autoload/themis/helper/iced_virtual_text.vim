let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {
      \ 'last_args': {},
      \ }

function! s:helper.set(text, ...) abort
    let opt = get(a:, 1, {})
    let self.last_args = {'set': {'text': a:text, 'opt': opt}}
endfunction

function! s:helper.clear(...) abort
    let opt = get(a:, 1, {})
    let self.last_args = {'clear': {'opt': opt}}
endfunction

function! s:helper.get_last_args() abort
  return self.last_args
endfunction

function! s:helper.mock(...) abort
  call iced#system#set_component('virtual_text', {'constructor': {_ -> self}})
endfunction

function! themis#helper#iced_virtual_text#new(runner) abort
  return deepcopy(s:helper)
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
