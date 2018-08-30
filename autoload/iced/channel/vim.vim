let s:save_cpo = &cpo
set cpo&vim

let s:ch = {
    \ 'env': 'vim',
    \ }

function! s:ch.open(address, options) dict
  return ch_open(a:address, a:options)
endfunction

function! s:ch.close(handle) dict
  return ch_close(a:handle)
endfunction

function! s:ch.status(handle) dict
  return ch_status(a:handle)
endfunction

function! s:ch.sendraw(handle, string) dict
  return ch_sendraw(a:handle, a:string)
endfunction

function! iced#channel#vim#new() abort
  return s:ch
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

