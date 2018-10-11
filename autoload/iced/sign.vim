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

function! iced#sign#jump_to_next() abort
  let lnum = line('.')
  let target = ''
  let sign_list = iced#sign#list_in_current_buffer()

  for sign in sign_list
    if sign['line'] > lnum
      let target = sign
      break
    endif
  endfor

  if empty(target) && &wrapscan && !empty(sign_list)
    call iced#message#info('search_hit_bottom')
    let target = sign_list[0]
  endif

  if empty(target)
    call iced#message#error('sign_not_found')
  else
    call cursor(target['line'], 1)
  endif
endfunction

function! iced#sign#jump_to_prev() abort
  let lnum = line('.')
  let tmp = ''
  let target = ''
  let sign_list = iced#sign#list_in_current_buffer()

  for sign in sign_list
    if sign['line'] < lnum
      let tmp = sign
    elseif sign['line'] >= lnum && !empty(tmp)
      let target = tmp
      break
    endif
  endfor

  if empty(target) && &wrapscan && !empty(sign_list)
    call iced#message#info('search_hit_top')
    let l = len(sign_list)
    let target = sign_list[l-1]
  endif

  if empty(target)
    call iced#message#error('sign_not_found')
  else
    call cursor(target['line'], 1)
  endif
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

function! iced#sign#refresh() abort
  let sign_list = iced#sign#list_in_current_buffer()
  for sign in sign_list
    call iced#sign#unplace(sign['id'])
    call iced#sign#place(sign['name'], sign['line'], sign['file'])
  endfor
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
