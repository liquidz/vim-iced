let s:save_cpo = &cpo
set cpo&vim

let s:cache = {}

function! iced#cache#set(k, v) abort
  let s:cache[a:k] = a:v
endfunction

function! iced#cache#get(k, ...) abort
  let default = get(a:, 1, v:none)
  return get(s:cache, a:k, default)
endfunction

function! iced#cache#merge(dict) abort
  call extend(s:cache, a:dict)
endfunction

function! iced#cache#clear() abort
  let s:cache = {}
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
