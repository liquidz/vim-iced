let s:save_cpo = &cpo
set cpo&vim

let s:cache = {}

function! iced#cache#set(k, v) abort
  let s:cache[a:k] = a:v
endfunction

function! iced#cache#get(k, ...) abort
  let default = get(a:, 1, '')
  return get(s:cache, a:k, default)
endfunction

function! iced#cache#has_key(k) abort
  return has_key(s:cache, a:k)
endfunction

function! iced#cache#delete(k) abort
  unlet s:cache[a:k]
endfunction

function! iced#cache#merge(dict) abort
  call extend(s:cache, a:dict)
endfunction

function! iced#cache#clear() abort
  let s:cache = {}
endfunction

function! iced#cache#do_once(key, f) abort
  let key = printf('iced_do_once_%s', a:key)
  if ! iced#cache#has_key(key)
    call a:f()
    call iced#cache#set(key, v:true)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
