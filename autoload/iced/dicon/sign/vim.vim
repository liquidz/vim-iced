let s:save_cpo = &cpo
set cpo&vim

let s:sign = {'env': 'vim'}

function! s:sign.place(id, lnum, name, file) abort
  exe printf(':sign place %d line=%d name=%s file=%s',
      \ a:id, a:lnum, a:name, a:file)
endfunction

function! s:sign.unplace(id) abort
  exe printf(':sign unplace %d', a:id)
endfunction

function! s:sign.unplace_all() abort
  sign unplace *
endfunction

function! iced#dicon#sign#vim#build() abort
  return s:sign
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
