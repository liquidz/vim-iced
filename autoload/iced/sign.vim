let s:save_cpo = &cpo
set cpo&vim

let s:id = 1
let s:sign_list = []

function! s:next_id() abort
  let res = s:id
  let s:id = s:id + 1
  return res
endfunction

function! iced#sign#place(name, lnum, file) abort
  let id = s:next_id()
  exe printf(':sign place %d line=%d name=%s file=%s',
      \ id, a:lnum, a:name, a:file)
  call add(s:sign_list, {'id': id, 'line': a:lnum, 'name': a:name, 'file': a:file})
  return id
endfunction

function! iced#sign#list_in_current_buffer() abort
  let file = get(a:, 1, expand('%:p'))
  let list = filter(copy(s:sign_list), {_, v -> v['file'] ==# file})
  return sort(list, {a, b -> a['line'] > b['line']})
endfunction

function! iced#sign#unplace(id) abort
  exe printf(':sign unplace %d', a:id)
  call filter(s:sign_list, {_, v -> v['id'] !=# a:id })
endfunction

function! iced#sign#unplace_all() abort
  sign unplace *
  let s:sign_list = []
  let s:id = 1
endfunction

function! iced#sign#place_error(lnum, ...) abort
  let file = get(a:, 1, expand('%:p'))
  call iced#sign#place('iced_err', a:lnum, file)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
