let s:save_cpo = &cpo
set cpo&vim

" NOTE: setting indentexpr is executed at nREPL connection
function! GetIcedIndent()
  return iced#format#calculate_indent(v:lnum)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
