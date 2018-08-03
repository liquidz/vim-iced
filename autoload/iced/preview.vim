let s:save_cpo = &cpo
set cpo&vim

let s:temp_file_path = tempname()

function! iced#preview#open() abort
  execute printf(':pedit %s', s:temp_file_path)
endfunction

function! iced#preview#view(text) abort
  if !empty(a:text)
    call writefile(split(a:text, '\r\?\n'), s:temp_file_path)
    call iced#preview#open()
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

