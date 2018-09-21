let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#iced#sync#system_info() abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  return iced#nrepl#sync#send({
        \ 'op': 'system-info',
        \ 'sesion': iced#nrepl#current_session(),
        \ })
endfunction

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

function! iced#nrepl#iced#sync#refactor_thread_first(code) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  return iced#nrepl#sync#send({
        \ 'id': iced#nrepl#eval#id(),
        \ 'op': 'refactor-thread-first',
        \ 'sesion': iced#nrepl#current_session(),
        \ 'code': a:code,
        \ })
endfunction

function! iced#nrepl#iced#sync#refactor_thread_last(code) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  return iced#nrepl#sync#send({
        \ 'id': iced#nrepl#eval#id(),
        \ 'op': 'refactor-thread-last',
        \ 'sesion': iced#nrepl#current_session(),
        \ 'code': a:code,
        \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
