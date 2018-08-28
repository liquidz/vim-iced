let s:save_cpo = &cpo
set cpo&vim

function! iced#highlight#set_by_position(grp, line, start_column, end_column) abort
  let start_line = max([a:line-1, 0])
  let end_line = a:line+1
  let start_column = max([a:start_column-1, 0])
  let end_column = a:end_column+2
  silent exec printf('match %s /\%%>%dl\%%<%dl\%%>%dv.\+\%%<%dv/',
      \ a:grp, start_line, end_line, start_column, end_column)
endfunction

function! iced#highlight#clear() abort
  match none
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
