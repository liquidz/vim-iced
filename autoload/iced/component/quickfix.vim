let s:save_cpo = &cpoptions
set cpoptions&vim

let s:qf = {}

function! s:qf.setlist(list, action) abort
  silent call setqflist(a:list, a:action)
endfunction

function! s:qf.setloclist(nr, list, action) abort
  silent call setloclist(a:nr, a:list, a:action)
endfunction

function! iced#component#quickfix#start(_) abort
  call iced#util#debug('start', 'quickfix')
  return s:qf
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
