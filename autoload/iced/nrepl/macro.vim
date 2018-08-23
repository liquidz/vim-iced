let s:save_cpo = &cpo
set cpo&vim

function! s:view(resp) abort
  if has_key(a:resp, 'expansion')
    call iced#buffer#document#open(a:resp['expansion'], 'clojure')
  endif
endfunction

function! iced#nrepl#macro#expand(code) abort
  call iced#nrepl#cider#macroexpand_all(a:code, funcref('s:view'))
endfunction

function! iced#nrepl#macro#expand_1(code) abort
  call iced#nrepl#cider#macroexpand_1(a:code, funcref('s:view'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
