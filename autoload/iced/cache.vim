let s:save_cpo = &cpoptions
set cpoptions&vim

let s:cache = {}

function! iced#cache#set(k, v) abort
  let s:cache[a:k] = a:v
  return a:v
endfunction

function! iced#cache#get(k, ...) abort
  let default = get(a:, 1, '')
  return get(s:cache, a:k, default)
endfunction

function! iced#cache#has_key(k) abort
  return has_key(s:cache, a:k)
endfunction

function! iced#cache#delete(k) abort
  let v = copy(s:cache[a:k])
  unlet s:cache[a:k]
  return v
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
    let ret = a:f()
    if !empty(ret)
      call iced#cache#set(key, ret)
    endif
    return ret
  else
    return iced#cache#get(key)
  endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
