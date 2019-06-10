let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {'args': []}

function! s:helper.run(...) abort
  call add(self.args, a:000)
endfunction

function! s:helper.clear() abort
  let self.args = []
endfunction

function! s:helper.get_args() abort
  return self.args
endfunction

function! themis#helper#iced_holder#new(runner) abort
  return deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
