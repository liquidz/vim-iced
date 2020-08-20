let s:save_cpo = &cpoptions
set cpoptions&vim

let s:qf = {}

function! s:qf.setlist(list, ...) abort
  " c.f. :h setqflist
  " > If {action} is set to ' ', then a new list is created.
  let action = get(a:, 1, ' ')
  silent call setqflist(a:list, action)
endfunction

function! s:qf.setloclist(nr, list, ...) abort
  let action = get(a:, 1, ' ')
  silent call setloclist(a:nr, a:list, action)
endfunction

function! iced#component#quickfix#start(_) abort
  call iced#util#debug('start', 'quickfix')
  return s:qf
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
