let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#system#info() abort
  let code = '[(System/getProperty "file.separator") (System/getProperty "user.dir")]'
  let resp = iced#nrepl#sync#send({
      \ 'id': iced#nrepl#eval#id(),
      \ 'op': 'eval',
      \ 'code': code,
      \ 'session': iced#nrepl#clj_session(),
      \ })

  if !has_key(resp, 'value')
    return v:none
  endif

  let v = substitute(resp['value'], '[\[\]"]', '', 'g')
  let v = split(v, ' ')
  return {
      \ 'separator': v[0],
      \ 'user_dir': join(v[1:], ' '),
      \ }
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
