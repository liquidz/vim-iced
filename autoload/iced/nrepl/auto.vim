let s:save_cpo = &cpo
set cpo&vim

let g:iced#nrepl#auto#does_switch_session = get(g:, 'iced#nrepl#auto#does_switch_session', v:false)
let s:leaving = v:false
let s:is_bufenter_enabled = v:false

function! s:auto_switching_session() abort
  if ! g:iced#nrepl#auto#does_switch_session | return | endif
  if iced#nrepl#check_session_validity(v:false) | return | endif

  let ext = expand('%:e')
  if ext ==# 'cljs' && iced#nrepl#cljs_session() !=# ''
    call iced#nrepl#change_current_session('cljs')
    call iced#hook#run('session_switched', {'session': 'cljs'})
  elseif ext ==# 'clj'
    call iced#nrepl#change_current_session('clj')
    call iced#hook#run('session_switched', {'session': 'clj'})
  endif
endfunction

function! iced#nrepl#auto#bufenter() abort
  if ! s:is_bufenter_enabled | return | endif

  if !iced#nrepl#is_connected() | return | endif
  call s:auto_switching_session()
  " eval `in-ns` automatically
  if ! iced#nrepl#check_session_validity(v:false) | return | endif
  call iced#nrepl#ns#in()
endfunction

function! iced#nrepl#auto#bufread() abort
  if !iced#nrepl#is_connected() | return | endif
  call s:auto_switching_session()
  if !iced#nrepl#check_session_validity(v:false) | return | endif

  let ns_name = iced#nrepl#ns#name()
  call iced#nrepl#ns#require(ns_name, {_ -> ''})
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

function! iced#nrepl#auto#enable_bufenter(bool) abort
  if type(a:bool) != v:t_bool | return | endif
  let s:is_bufenter_enabled = a:bool
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
