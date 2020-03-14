let s:save_cpo = &cpoptions
set cpoptions&vim

let s:sign = {
      \ 'global_prefix': 'iced_',
      \ 'default_group': 'default',
      \ 'ex_cmd': '',
      \ }

function! s:sign.place(name, lnum, file, ...) abort
  if !filereadable(a:file) | return | endif

  let group = get(a:, 1, self.default_group)

  try
    return sign_place(0, group, a:name, a:file, {'lnum': a:lnum})
  catch /E158:/
    " Invalid buffer name
    call self.ex_cmd.exe(printf(':edit %s | buffer %d', a:file, bufnr('%')))
    return sign_place(0, group, a:name, a:file, {'lnum': a:lnum})
  endtry
endfunction

function! s:sign.list_in_buffer(...) abort
  let file = get(a:, 1, expand('%:p'))
  let list = sign_getplaced(file, {'group': '*'})
  try
    let signs = list[0]['signs']
    " Filter only to vim-iced signs
    return filter(signs, {_, v -> stridx(v['name'], self.global_prefix) == 0})
  catch
    return []
  endtry
endfunction

function! s:sign.list_all() abort
  let res = []
  let buffers = filter(range(1, bufnr('$')), {_, i -> bufexists(i)})
  for nr in buffers
    call extend(res, self.list_in_buffer(nr))
  endfor
  return res
endfunction

function! s:sign.jump_to_next(...) abort
  let lnum = line('.')
  let opt = get(a:, 1, {})
  let file = get(opt, 'file', expand('%:p'))
  let name = get(opt, 'name', '')
  let sign_list = self.list_in_buffer(file)
  let target = ''

  if !empty(name)
    call filter(sign_list, {_, v -> v['name'] ==# name})
  endif

  for sign in sign_list
    if sign['lnum'] > lnum
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
    call sign_jump(target['id'], target['group'], '')
  endif
endfunction

function! s:sign.jump_to_prev(...) abort
  let lnum = line('.')
  let opt = get(a:, 1, {})
  let file = get(opt, 'file', expand('%:p'))
  let name = get(opt, 'name', '')
  let tmp = ''
  let target = ''
  let sign_list = self.list_in_buffer(file)

  if !empty(name)
    call filter(sign_list, {_, v -> v['name'] ==# name})
  endif

  for sign in sign_list
    if sign['lnum'] < lnum
      let tmp = sign
    elseif sign['lnum'] >= lnum && !empty(tmp)
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
    call sign_jump(target['id'], target['group'], '')
  endif
endfunction


function! s:sign.unplace_by(opt) abort
  let group = get(a:opt, 'group', self.default_group)
  let file = get(a:opt, 'file', '')

  if empty(file)
    let signs = self.list_all()
  else
    let signs = self.list_in_buffer(file)
  endif

  if group !=# '*'
    call filter(signs, {_, v -> v['group'] ==# group})
  endif

  if has_key(a:opt, 'id')
    call filter(signs, {_, v -> v['id'] ==# a:opt.id})
  endif

  if has_key(a:opt, 'name')
    call filter(signs, {_, v -> v['name'] ==# a:opt.name})
  endif

  for sign in signs
    call sign_unplace(sign['group'], {'id': sign['id']})
  endfor
endfunction

function! s:sign.refresh(...) abort
  let opt = get(a:, 1, {})
  let file = get(opt, 'file', expand('%:p'))
  let signs = get(opt, 'signs', self.list_in_buffer())

  for sign in signs
    call self.unplace_by({'id': sign['id'], 'group': sign['group']})
    call self.place(sign['name'], sign['lnum'], file, sign['group'])
  endfor
endfunction

function! iced#component#sign#start(this) abort
  call iced#util#debug('start', 'sign')
  let d = deepcopy(s:sign)
  let d['ex_cmd'] = a:this.ex_cmd
  return d
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
