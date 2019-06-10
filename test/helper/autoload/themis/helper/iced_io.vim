let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {
      \ 'value': {},
      \ 'last_args': {},
      \ }

function! s:helper.input(prompt) abort
  let self.last_args = {'input': {'prompt': a:prompt}}
  return get(self.value, 'input', '')
endfunction

function! s:helper.echomsg(hl, text) abort
  let self.last_args = {'echomsg': {'hl': a:hl, 'text': a:text}}
  return ''
endfunction

function! s:helper.get_last_args() abort
  return self.last_args
endfunction

function! s:helper.register_test_builder(...) abort
  let self.value = get(a:, 1, {})
  call iced#di#register('io', {_ -> self})
endfunction

function! themis#helper#iced_io#new(runner) abort
  return deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
