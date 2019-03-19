let s:save_cpo = &cpo
set cpo&vim

let s:ch = {
    \ 'env': 'vim',
    \ }

function! s:ch.open(address, options) abort
  return ch_open(a:address, a:options)
endfunction

function! s:ch.close(handler) abort
  return ch_close(a:handler)
endfunction

function! s:ch.status(handler) abort
  return ch_status(a:handler)
endfunction

function! s:ch.sendraw(handler, string) abort
  return ch_sendraw(a:handler, a:string)
endfunction

function! iced#state#channel#vim#start(_) abort
  return s:ch
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
