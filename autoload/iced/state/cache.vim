let s:save_cpo = &cpo
set cpo&vim

let s:cache = {'data': {}}

function! s:cache.set(k, v) abort
  let self.data[a:k] = a:v
endfunction

function! s:cache.get(k, ...) abort
  let default = get(a:, 1, '')
  return get(self.data, a:k, default)
endfunction

function! s:cache.has_key(k) abort
  return has_key(self.data, a:k)
endfunction

function! s:cache.delete(k) abort
  unlet self.data[a:k]
endfunction

function! s:cache.merge(dict) abort
  call extend(self.data, a:dict)
endfunction

function! s:cache.clear() abort
  let self.data = {}
endfunction

function! s:cache.do_once(key, f) abort
  let key = printf('iced_do_once_%s', a:key)
  if ! self.has_key(key)
    let ret = a:f()
    if !empty(ret)
      call self.set(key, ret)
    endif
    return ret
  else
    return self.get(key)
  endif
endfunction

function! iced#state#cache#start(_) abort
  return deepcopy(s:cache)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
