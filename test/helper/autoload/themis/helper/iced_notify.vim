let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {
      \ 'last_args': {},
      \ }

function! s:helper.notify(text, ...) abort
  let self.last_args = {'notify': {'text': a:text, 'option': get(a:, 1, {})}}
  return ''
endfunction

function! s:helper.get_last_args() abort
  return self.last_args
endfunction

function! s:helper.mock() abort
  call iced#system#set_component('notify', {'start': {_ -> self}})
endfunction

function! themis#helper#iced_notify#new(runner) abort
  return deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
