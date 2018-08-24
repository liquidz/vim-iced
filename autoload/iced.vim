let s:save_cpo = &cpo
set cpo&vim

let g:iced#debug = v:false

function! iced#status() abort
  if !iced#nrepl#is_connected()
    return 'not connected'
  endif

  if iced#nrepl#is_evaluating()
    return 'evaluating'
  else
    return printf('%s repl', iced#nrepl#current_session_key())
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
