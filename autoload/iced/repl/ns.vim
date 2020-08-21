let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:__list(callback, resp) abort
  let list = get(a:resp, 'value', '')
  let list = split(substitute(list, '(\|)', '', 'g'), ' \+')
  " as same as cider-nrepl's ns-list op
  return a:callback({'ns-list': copy(list)})
endfunction

function! iced#repl#ns#list(callback) abort
  call iced#repl#execute('eval_code', '(map ns-name (all-ns))', {
        \ 'callback': funcref('s:__list', [a:callback]),
        \ })
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
