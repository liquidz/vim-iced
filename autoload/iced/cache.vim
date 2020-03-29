let s:save_cpo = &cpoptions
set cpoptions&vim

let s:cache = {}

function! s:expire_key(k) abort
  return printf('__%s__expire__', a:k)
endfunction

function! iced#cache#set(k, v, ...) abort
  let s:cache[a:k] = a:v

  let expire_seconds = get(a:, 1, '')
  if !empty(expire_seconds)
    let s:cache[s:expire_key(a:k)] = [expire_seconds, reltime()]
  endif

  return a:v
endfunction

function! iced#cache#get(k, ...) abort
  let default = get(a:, 1, '')
  let ex_k = s:expire_key(a:k)

  let [expire_seconds, start_time] = get(s:cache, ex_k, [999, reltime()])
  if reltimefloat(reltime(start_time)) > expire_seconds
    call iced#cache#delete(a:k)
    call iced#cache#delete(ex_k)
    return default
  endif

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
