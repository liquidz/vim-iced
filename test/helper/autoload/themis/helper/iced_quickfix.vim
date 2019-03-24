let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {'last_args': []}

function! s:helper.setlist(list, action) abort
  let self.last_args = {'list': a:list, 'action': a:action}
endfunction

function! s:helper.start_test_state() abort
  call iced#state#define('quickfix', {'start': {_ -> self}})
  call iced#state#start_by_name('quickfix')
endfunction

function! s:helper.get_last_args() abort
  return self.last_args
endfunction

function! themis#helper#iced_quickfix#new(runner) abort
  return  deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
