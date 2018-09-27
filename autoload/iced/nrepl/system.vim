let s:save_cpo = &cpo
set cpo&vim

function! s:select_keys(dict, keys) abort
  let res = {}
  for k in a:keys
    let res[k] = a:dict[k]
  endfor
  return res
endfunction

function! iced#nrepl#system#info() abort
  if !iced#nrepl#is_connected() | return {} | endif
  let resp = iced#nrepl#op#iced#sync#system_info()

  if !has_key(resp, 'user-dir')
    return {}
  endif

  return s:select_keys(resp, ['user-dir', 'file-separator', 'project-name'])
endfunction

function! s:update_cache() abort
  let info = iced#nrepl#system#info()
  if has_key(info, 'user-dir')
    call iced#cache#merge(info)
  endif
  return info
endfunction

function! s:get(key) abort
  let val = iced#cache#get(a:key)
  if val != v:none | return val | endif
  return get(s:update_cache(), a:key)
endfunction

function! iced#nrepl#system#user_dir() abort
  return s:get('user-dir')
endfunction

function! iced#nrepl#system#separator() abort
  return s:get('file-separator')
endfunction

function! iced#nrepl#system#project_name() abort
  return s:get('project-name')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
