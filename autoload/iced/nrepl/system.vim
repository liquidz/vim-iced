let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#system#info() abort
  if !iced#nrepl#is_connected() | return {} | endif
  let code = '[(System/getProperty "file.separator") (System/getProperty "user.dir")]'
  let resp = iced#nrepl#sync#send({
      \ 'id': iced#nrepl#eval#id(),
      \ 'op': 'eval',
      \ 'code': code,
      \ 'session': iced#nrepl#clj_session(),
      \ })

  if !has_key(resp, 'value')
    return {}
  endif

  let v = substitute(resp['value'], '[\[\]"]', '', 'g')
  let v = split(v, ' ')
  return {
      \ 'separator': v[0],
      \ 'user_dir': join(v[1:], ' '),
      \ }
endfunction

function! s:update_cache() abort
  let info = iced#nrepl#system#info()
  if has_key(info, 'user_dir')
    call iced#cache#merge(info)
  endif
  return info
endfunction

function! iced#nrepl#system#user_dir() abort
  let dir = iced#cache#get('user_dir')
  if dir != v:none | return dir | endif
  echo 'oo'
  return get(s:update_cache(), 'user_dir')
endfunction

function! iced#nrepl#system#separator() abort
  let sep = iced#cache#get('separator')
  if sep != v:none | return sep | endif
  return get(s:update_cache(), 'separator')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
