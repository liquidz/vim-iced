let s:save_cpo = &cpo
set cpo&vim

let s:system_info_code = join([
      \ '(clojure.core/let [user-dir (System/getProperty "user.dir")',
      \ '                   sep (System/getProperty "file.separator")]',
      \ '  {:user-dir user-dir',
      \ '   :file-separator sep',
      \ '   :project-name (-> (.split user-dir sep) clojure.core/seq clojure.core/last)})'
      \ ], "\n")

function! iced#nrepl#system#info() abort
  if !iced#nrepl#is_connected() | return {} | endif
  let resp = iced#eval_and_read(s:system_info_code)

  if !has_key(resp, 'value') | return {} | endif
  return resp['value']
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
  if !empty(val) | return val | endif
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
