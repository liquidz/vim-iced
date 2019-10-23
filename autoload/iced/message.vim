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

function! iced#message#get(k, ...) abort
  let msg = s:msg.get(a:k)
  if !empty(a:000)
    let msg = call('printf', [msg] + a:000)
  endif
  return msg
endfunction

function! s:echom(hl, s) abort
  let io = iced#system#get('io')
  for line in split(a:s, '\r\?\n')
    call io.echomsg(a:hl, line)
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

function! iced#message#echom(k, ...) abort
  let msg = iced#message#get(a:k)
  if !empty(a:000)
    let msg = call('printf', [msg] + a:000)
  endif
  echom msg
endfunction

function! iced#message#info(k, ...) abort
  let msg = iced#message#get(a:k)
  if !empty(a:000)
    let msg = call('printf', [msg] + a:000)
  endif
  call iced#message#info_str(msg)
endfunction

function! iced#message#warning(k, ...) abort
  let msg = iced#message#get(a:k)
  if !empty(a:000)
    let msg = call('printf', [msg] + a:000)
  endif
  call iced#message#warning_str(msg)
endfunction

function! iced#message#error(k, ...) abort
  let msg = iced#message#get(a:k)
  if !empty(a:000)
    let msg = call('printf', [msg] + a:000)
  endif
  call iced#message#error_str(msg)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
