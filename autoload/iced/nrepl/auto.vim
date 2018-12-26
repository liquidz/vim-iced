let s:save_cpo = &cpo
set cpo&vim

let s:leaving = v:false

function! iced#nrepl#auto#bufread() abort
  if !iced#nrepl#is_connected() | return | endif
  if !iced#nrepl#check_session_validity(v:false) | return | endif
  call iced#nrepl#ns#eval({_ -> ''})
  call iced#format#set_indentexpr()
endfunction

function! iced#nrepl#auto#bufwrite_post() abort
  let timer = {}
  function! timer.callback(_) abort
    if !s:leaving
      call iced#lint#current_file()
    endif
  endfunction

  call timer_start(500, timer.callback)
endfunction

function! iced#nrepl#auto#newfile() abort
  if !iced#nrepl#is_connected() | return | endif
  call iced#skeleton#new()
  call iced#format#set_indentexpr()
endfunction

function! iced#nrepl#auto#leave() abort
  let s:leaving = v:true
  call iced#nrepl#disconnect()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
