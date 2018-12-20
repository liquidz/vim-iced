let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#auto#bufread() abort
  if !iced#nrepl#is_connected() | return | endif
  if !iced#nrepl#check_session_validity(v:false) | return | endif
  call iced#nrepl#ns#eval({_ -> ''})
  call iced#format#set_indentexpr()
endfunction

function! iced#nrepl#auto#newfile() abort
  if !iced#nrepl#is_connected() | return | endif
  call iced#skeleton#new()
  call iced#format#set_indentexpr()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
