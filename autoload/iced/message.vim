let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:M = s:V.import('Vim.Message')
let s:LM = s:V.import('Locale.Message')
let s:msg = s:LM.new('iced')

let s:supported_langs = ['en']
if stridx(join(s:supported_langs, ','), s:LM.get_lang()) == -1
  call s:msg.load(s:supported_langs[0])
endif

function! iced#message#get(k) abort
  return s:msg.get(a:k)
endfunction

function! s:echom(hl, s) abort
  for line in split(a:s, '\r\?\n')
    call s:M.echomsg(a:hl, line)
  endfor
endfunction

function! iced#message#info_str(s) abort
  call s:echom('MoreMsg', a:s)
endfunction

function! iced#message#warning_str(s) abort
  call s:echom('WarningMsg', a:s)
endfunction

function! iced#message#error_str(s) abort
  call s:echom('ErrorMsg', a:s)
endfunction

function! iced#message#echom(k) abort
  echom iced#message#get(a:k)
endfunction

function! iced#message#info(k) abort
  call iced#message#info_str(iced#message#get(a:k))
endfunction

function! iced#message#warning(k) abort
  call iced#message#warning_str(iced#message#get(a:k))
endfunction

function! iced#message#error(k) abort
  call iced#message#error_str(iced#message#get(a:k))
endfunction

function! iced#message#test(k) abort
  return s:msg.get(a:k)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
