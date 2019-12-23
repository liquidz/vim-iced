let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {}

function! s:helper.mock() abort
  let nrepl = deepcopy(iced#system#get('nrepl'))
  let nrepl['connect'] = {_ -> ''}
  call iced#system#set_component('test_nrepl', {'start': {_ -> nrepl}})
  call iced#repl#connect('test_nrepl', '')
endfunction

function! themis#helper#iced_repl#new(runner) abort
  return deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
