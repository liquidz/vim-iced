let s:save_cpo = &cpoptions
set cpoptions&vim

let s:script_path = printf('%s/bencode.vim9script', expand('<sfile>:h'))
import s:script_path as that
let s:bencode = {}

function! s:bencode.encode(v) abort
  return s:that.Encode(a:v)
endfunction

function! s:bencode.decode(s) abort
  return s:that.Decode(a:s)
endfunction

function! iced#component#bencode#vim9#start(_) abort
  call iced#util#debug('start', 'vim9 bencode')
  return s:bencode
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
