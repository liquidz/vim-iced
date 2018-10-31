let s:save_cpo = &cpo
set cpo&vim

let s:ch = {
    \ 'env': 'vim',
    \ }

function! s:ch.open(address, options) abort
  return ch_open(a:address, a:options)
endfunction

function! s:ch.close(handle) abort
  return ch_close(a:handle)
endfunction

function! s:ch.status(handle) abort
  return ch_status(a:handle)
endfunction

function! s:ch.sendraw(handle, string) abort
  return ch_sendraw(a:handle, a:string)
endfunction

function! iced#di#channel#vim#build() abort
  return s:ch
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
