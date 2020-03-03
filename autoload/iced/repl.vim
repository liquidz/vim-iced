let s:save_cpo = &cpo
set cpo&vim

let s:repl = {}

function! iced#repl#status() abort
  if empty(s:repl) | return 'not connected' | endif
  return s:repl.status()
endfunction

function! iced#repl#is_connected() abort
  if empty(s:repl) | return v:false | endif
  return s:repl.is_connected()
endfunction

function! iced#repl#connect(target, ...) abort
  let s:repl = iced#system#get(a:target)
  if empty(s:repl)
    return iced#message#error('connect_error')
  endif

  call call(s:repl.connect, a:000)

  return s:repl
endfunction

function! iced#repl#get(feature_name) abort
  return get(s:repl, a:feature_name)
endfunction

function! iced#repl#execute(feature_name, ...) abort
  let Fn = get(s:repl, a:feature_name)
  if type(Fn) == v:t_func
    return call(Fn, a:000)
  endif
  throw printf('Invalid feature: %s', a:feature_name)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
