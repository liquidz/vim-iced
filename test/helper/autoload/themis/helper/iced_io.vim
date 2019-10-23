let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {
      \ 'value': {},
      \ 'last_args': {},
      \ }

function! s:helper.input(...) abort
  let self.last_args = {'input': {'prompt': get(a:, 1, ''), 'text': get(a:, 2, '')}}
  return get(self.value, 'input', '')
endfunction

function! s:helper.echomsg(hl, text) abort
  let self.last_args = {'echomsg': {'hl': a:hl, 'text': a:text}}
  return ''
endfunction

function! s:helper.get_last_args() abort
  return self.last_args
endfunction

function! s:helper.mock(...) abort
  let self.value = get(a:, 1, {})
  call iced#system#set_component('io', {'constructor': {_ -> self}})
endfunction

function! themis#helper#iced_io#new(runner) abort
  return deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
