let s:save_cpo = &cpoptions
set cpoptions&vim

function! iced#component#sign#start(this) abort
  call iced#util#debug('start', 'sign')
  let d = {
        \ 'default_group': 'default',
        \ 'ex_cmd': a:this.ex_cmd,
        \ }

  function! d.place(name, lnum, file, ...) abort
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

  function! d.list_in_buffer(...) abort
    let file = get(a:, 1, expand('%:p'))
    let list = sign_getplaced(file, {'group': '*'})
    try
      return list[0]['signs']
    catch
      return []
    endtry
  endfunction

  function! d.jump_to_next(...) abort
    let lnum = line('.')
    let file = get(a:, 1, expand('%:p'))
    let sign_list = self.list_in_buffer(file)
    let target = ''

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

  function! d.jump_to_prev(...) abort
    let lnum = line('.')
    let file = get(a:, 1, expand('%:p'))
    let tmp = ''
    let target = ''
    let sign_list = self.list_in_buffer(file)

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

  function! d.unplace_by(opt) abort
    let group = get(a:opt, 'group', self.default_group)
    let file = get(a:opt, 'file', '')
    let signs = sign_getplaced(file, {'group': '*'})[0]['signs']

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

  function! d.refresh(...) abort
    let file = get(a:, 1, expand('%:p'))
    for sign in self.list_in_buffer()
      call self.unplace_by({'id': sign['id'], 'group': sign['group']})
      call self.place(sign['name'], sign['lnum'], file)
    endfor
  endfunction

  return d
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
