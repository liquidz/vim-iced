let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {}

function! s:helper.mock(...) abort
  let component_name = get(a:, 1, 'nrepl')
  let repl = deepcopy(iced#system#get(component_name))
  if type(repl) != v:t_dict
    let repl = {}
  endif
  let repl['connect'] = {_ -> v:true}
  call iced#system#set_component('test_repl', {'start': {_ -> repl}})
  call iced#repl#connect('test_repl', '')
endfunction

function! themis#helper#iced_repl#new(runner) abort
  return deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
