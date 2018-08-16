let s:save_cpo = &cpo
set cpo&vim

function! s:view(result) abort
  if has_key(a:result, 'value')
    call iced#preview#view(a:result.value, 'clojure')
  endif
endfunction

function! iced#nrepl#macro#expand(code) abort
  let code = printf('(macroexpand ''%s)', a:code)
  call iced#nrepl#eval(code, function('s:view'))
endfunction

function! iced#nrepl#macro#expand_1(code) abort
  let code = printf('(macroexpand-1 ''%s)', a:code)
  call iced#nrepl#eval(code, function('s:view'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
