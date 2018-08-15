let s:save_cpo = &cpo
set cpo&vim

let s:temp_file_path = tempname()

function! iced#preview#bufnr() abort
  let ls = map(getbufinfo(), {_, v -> v['bufnr']})
  for nr in filter(ls, {_, v -> bufwinnr(v) != -1})
    if getwinvar(bufwinnr(nr), '&previewwindow') == 1
      return nr
    endif
  endfor
  return -1
endfunction

function! iced#preview#type(...) abort
  let nr = iced#preview#bufnr()
  let default_value = get(a:, 1, v:none)
  if nr == -1
    return default_value
  endif

  return getbufvar(nr, 'preview_type', default_value)
endfunction

function! iced#preview#set_type(v) abort
  let nr = iced#preview#bufnr()
  if nr == -1
    return
  endif

  call setbufvar(nr, 'preview_type', a:v)
endfunction

function! iced#preview#open() abort
  execute printf(':pedit %s', s:temp_file_path)
  call iced#preview#set_type(v:none)
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

