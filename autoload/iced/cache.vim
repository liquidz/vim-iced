let s:save_cpo = &cpoptions
set cpoptions&vim

let s:cache = {}

let s:limit = 60 * 60 * 24 * 7 " 1 week

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

  let [expire_seconds, start_time] = get(s:cache, ex_k, [s:limit, reltime()])
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
  if has_key(s:cache, a:k)
    let v = copy(s:cache[a:k])
    unlet s:cache[a:k]
    return v
  endif
endfunction

function! iced#cache#delete_by_prefix(prefix) abort
  let res = []
  for k in keys(s:cache)
    if stridx(k, a:prefix) == 0
      call add(res, copy(s:cache[k]))
      unlet s:cache[k]
    endif
  endfor

  return res
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

function! iced#cache#factory(prefix) abort
  let d = {'__prefix__': a:prefix}
  function! d.__key__(k) abort
    return printf('%s-%s', self.__prefix__, a:k)
  endfunction

  function! d.set(k, v, ...) abort
    return iced#cache#set(self.__key__(a:k), a:v, get(a:, 1, ''))
  endfunction

  function! d.get(k, ...) abort
    return iced#cache#get(self.__key__(a:k), get(a:, 1, ''))
  endfunction

  function! d.delete(k) abort
    return iced#cache#delete(self.__key__(a:k))
  endfunction

  function! d.clear() abort
    return iced#cache#delete_by_prefix(self.__prefix__)
  endfunction

  return d
endfunction

let s:temp_dir = fnamemodify(tempname(), ':h')
function! iced#cache#directory() abort
  if !empty(g:iced_cache_directory)
    return g:iced_cache_directory
  endif

  let iced = 'vim-iced'
  let result = s:temp_dir

  if has('macunix')
    let result = join([$HOME, 'Library', 'Caches', iced], '/')
  elseif has('unix')
    if empty($XDG_CACHE_HOME)
      let result = join(['$HOME', '.cache', iced], '/')
    else
      let result = join([$XDG_CACHE_HOME, iced], '/')
    endif
  endif

  if !isdirectory(result)
    call mkdir(result, 'p')
  endif

  return result
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
