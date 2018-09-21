let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#auto#bufread() abort
  if !iced#nrepl#is_connected() | return | endif
  call iced#nrepl#ns#eval({_ -> v:none})
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
