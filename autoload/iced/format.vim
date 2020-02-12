let s:save_cpo = &cpo
set cpo&vim

function! iced#format#set_indentexpr() abort
  if get(g:, 'iced_enable_auto_indent', v:true)
    setlocal indentexpr=GetIcedIndent()
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
