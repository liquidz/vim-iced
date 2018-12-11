let g:iced_enable_auto_indent = get(g:, 'iced_enable_auto_indent', v:true)
if exists('b:did_indent') || !g:iced_enable_auto_indent
  finish
endif

setlocal autoindent
setlocal indentexpr=GetIcedIndent()
setlocal indentkeys=!^F,o,O

setlocal expandtab
setlocal tabstop<
setlocal softtabstop=2
setlocal shiftwidth=2

function! GetIcedIndent()
  return iced#format#calculate_indent(v:lnum)
endfunction

let b:did_indent = 1
