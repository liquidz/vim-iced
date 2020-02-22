let s:save_cpo = &cpoptions
set cpoptions&vim

let s:V = vital#iced#new()
let s:M = s:V.import('Vim.Message')
let s:io = {}

function! s:io.input(...) abort
  return call(function('input'), a:000)
endfunction

function! s:io.echomsg(hl, text) abort
  call s:M.echomsg(a:hl, a:text)
endfunction

function! s:io.echo(text) abort
  echo a:text
endfunction

function! s:io.feedkeys(ks, mode) abort
  return feedkeys(a:ks, a:mode)
endfunction

function! iced#component#io#start(_) abort
  call iced#util#debug('start', 'io')
  return s:io
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
