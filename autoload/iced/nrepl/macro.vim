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

function! iced#nrepl#macro#expand_outer_list() abort
  let code = iced#paredit#get_outer_list()
  if empty(code)
    echom iced#message#get('finding_code_error')
  else
    call iced#nrepl#macro#expand(code)
  endif
endfunction

function! iced#nrepl#macro#expand_1_outer_list() abort
  let code = iced#paredit#get_outer_list()
  if empty(code)
    echom iced#message#get('finding_code_error')
  else
    call iced#nrepl#macro#expand_1(code)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
