let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#iced#sync#format_code(code, indents) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  return iced#nrepl#sync#send({
        \ 'id': iced#nrepl#eval#id(),
        \ 'op': 'format-code-with-indents',
        \ 'sesion': iced#nrepl#current_session(),
        \ 'code': a:code,
        \ 'indents': a:indents,
        \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
