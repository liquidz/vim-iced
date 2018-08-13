let s:save_cpo = &cpo
set cpo&vim

let s:id = 1

function! s:next_id() abort
  let res = s:id
  let s:id = s:id + 1
  return res
endfunction

function! iced#sign#place(name, lnum, file) abort
  exe printf(':sign place %d line=%d name=%s file=%s',
      \ s:next_id(), a:lnum, a:name, a:file)
endfunction

function! iced#sign#unplace_all() abort
  sign unplace *
  let s:id = 1
endfunction

function! iced#sign#place_error(lnum, ...) abort
  let file = get(a:, 1, expand('%:p'))
  call iced#sign#place('iced_err', a:lnum, file)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
