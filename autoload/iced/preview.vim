let s:save_cpo = &cpo
set cpo&vim

let s:temp_file_path = tempname()

function! iced#preview#open() abort
  execute printf(':pedit %s', s:temp_file_path)
endfunction

function! iced#preview#view(text, ...) abort
  if !empty(a:text)
    let ft = get(a:, 1, 'text')
    call writefile(split(a:text, '\r\?\n'), s:temp_file_path)
    call writefile(['', printf('vim:ft=%s', ft)], s:temp_file_path, 'a')
    call iced#preview#open()
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

