let s:save_cpo = &cpo
set cpo&vim

let s:formatter = printf('format_%s', get(g:, 'iced_formatter', 'default'))

function! iced#format#all() abort
  return iced#system#get(s:formatter).all()
endfunction

function! iced#format#current() abort
  return iced#system#get(s:formatter).current_form()
endfunction

function! iced#format#minimal(...) abort
  return iced#system#get(s:formatter).minimal(get(a:, 1, {}))
endfunction

function! iced#format#calculate_indent(lnum) abort
  return iced#system#get(s:formatter).calculate_indent(a:lnum)
endfunction

function! s:set_indentexpr() abort
  setlocal indentexpr=GetIcedIndent()
endfunction

function! iced#format#set_indentexpr() abort
  if get(g:, 'iced_enable_auto_indent', v:true)
    " Delay `setlocal` if called by ftplugin, because `GetIcedIndent` is not yet loaded
    call iced#system#get('future').do({-> s:set_indentexpr()})
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
