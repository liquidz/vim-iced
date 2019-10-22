let s:save_cpo = &cpoptions
set cpoptions&vim

let s:id = 1
let s:sign_list = []

let s:default_group = 'default'

function! s:next_id() abort
  let res = s:id
  let s:id = s:id + 1
  return res
endfunction

function! iced#sign#place(name, lnum, file, ...) abort
  if !filereadable(a:file) | return | endif

  let id = s:next_id()
  let ex = iced#di#get('ex_cmd')
  let group = get(a:, 1, s:default_group)
  try
    call ex.exe(printf(':sign place %d line=%d name=%s group=%s file=%s',
          \ id, a:lnum, a:name, group, a:file))
  catch /E158:/
    " Invalid buffer name
    let current_buf = bufnr('%')
    call ex.exe(printf(':edit %s | buffer %d | sign place %d line=%d name=%s file=%s',
          \ a:file, current_buf, id, a:lnum, a:name, a:file))
  endtry
  call add(s:sign_list, {
        \ 'id': id,
        \ 'line': a:lnum,
        \ 'name': a:name,
        \ 'group': group,
        \ 'file': a:file})
  return id
endfunction

function! iced#sign#list_in_current_buffer(...) abort
  let file = get(a:, 1, expand('%:p'))
  let list = filter(copy(s:sign_list), {_, v -> v['file'] ==# file})
  return sort(list, {a, b -> a['line'] > b['line']})
endfunction

function! iced#sign#jump_to_next(...) abort
  let lnum = line('.')
  let file = get(a:, 1, expand('%:p'))
  let target = ''
  let sign_list = iced#sign#list_in_current_buffer(file)

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

function! iced#sign#jump_to_prev(...) abort
  let lnum = line('.')
  let file = get(a:, 1, expand('%:p'))
  let tmp = ''
  let target = ''
  let sign_list = iced#sign#list_in_current_buffer(file)

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

function! iced#sign#unplace(id, ...) abort
  let group = get(a:, 1, s:default_group)
  call iced#di#get('ex_cmd').exe(printf(':sign unplace %d group=%s',
        \ a:id, group))
  call filter(s:sign_list, {_, v -> v['id'] !=# a:id || v['group'] !=# group })
endfunction

function! iced#sign#unplace_all() abort
  call iced#di#get('ex_cmd').exe(':sign unplace *')
  let s:sign_list = []
  let s:id = 1
endfunction

function! iced#sign#unplace_by_name(name) abort
  let file = get(a:, 1, expand('%:p'))
  for sign in s:sign_list
    if sign['name'] ==# a:name
      call iced#di#get('ex_cmd').exe(printf(':sign unplace %d group=%s',
            \ sign['id'], sign['group']))
    endif
  endfor
  call filter(s:sign_list, {_, v -> v['name'] !=# a:name })
endfunction

function! iced#sign#unplace_by_group(group) abort
  let unplace_ids = []
  for sign in iced#sign#list_in_current_buffer()
    if sign['group'] ==# a:group
      call iced#di#get('ex_cmd').exe(printf(':sign unplace %d group=%s',
            \ sign['id'], sign['group']))
      call add(unplace_ids, sign['id'])
    endif
  endfor
  call filter(s:sign_list, {_, v -> index(unplace_ids, v['id']) == -1})
endfunction

function! iced#sign#refresh() abort
  let sign_list = iced#sign#list_in_current_buffer()
  for sign in sign_list
    call iced#sign#unplace(sign['id'])
    call iced#sign#place(sign['name'], sign['line'], sign['file'])
  endfor
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
