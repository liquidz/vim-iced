let s:save_cpo = &cpoptions
set cpoptions&vim

let s:bufname = 'iced_temporary'
let s:current_window = -1

function! s:initialize(bufnr) abort
  call setbufvar(a:bufnr, '&bufhidden', 'hide')
  call setbufvar(a:bufnr, '&buflisted', 0)
  call setbufvar(a:bufnr, '&buftype', 'nofile')
  call setbufvar(a:bufnr, '&swapfile', 0)
endfunction

function! iced#buffer#temporary#init() abort
  return iced#buffer#init(s:bufname, funcref('s:initialize'))
endfunction

function! iced#buffer#temporary#begin() abort
  let s:current_window = winnr()
  call iced#buffer#open(s:bufname, {'opener': 'split'})
  call iced#buffer#clear(s:bufname)
  call iced#buffer#focus(s:bufname)
endfunction

function! iced#buffer#temporary#end() abort
  if s:current_window > 0
    execute s:current_window . 'wincmd w'
    call iced#buffer#close(s:bufname)
  endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
