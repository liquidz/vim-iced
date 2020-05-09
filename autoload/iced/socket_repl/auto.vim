let s:save_cpo = &cpoptions
set cpoptions&vim

let s:is_bufenter_enabled = v:false

function! iced#socket_repl#auto#enable_bufenter(bool) abort
  if type(a:bool) != v:t_bool | return | endif
  let s:is_bufenter_enabled = a:bool
endfunction

function! iced#socket_repl#auto#bufenter() abort
  if ! s:is_bufenter_enabled | return | endif
  if !iced#socket_repl#is_connected() | return | endif

  " eval `in-ns` automatically
  let ns_name = iced#nrepl#ns#name_by_buf()
  let ns_name = (empty(ns_name))
        \ ? iced#socket_repl#init_ns()
        \ : ns_name
  if !empty(ns_name)
    call iced#socket_repl#eval(printf('(in-ns ''%s)', ns_name), {'callback': {_ -> ''}})
  endif
endfunction

function!  s:__bufread_ns_required(_) abort
  let b:iced_ns_loaded = 1
  return v:true
endfunction

function! iced#socket_repl#auto#bufread() abort
  if !iced#socket_repl#is_connected() | return | endif
  " Skip to require ns if already loaded
  if exists('b:iced_ns_loaded') | return | endif

  let ns_code = iced#nrepl#ns#get()
  call iced#socket_repl#eval(ns_code, {'callback': funcref('s:__bufread_ns_required')})
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
