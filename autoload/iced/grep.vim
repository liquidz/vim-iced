let s:save_cpo = &cpoptions
set cpoptions&vim

let g:iced#grep#prg = get(g:, 'iced#grep#prg', 'git grep --no-index -I --line-number --no-color')
let g:iced#grep#format = get(g:, 'iced#grep#format', '%f:%l:%m,%f:%l%m,%f  %l%m')

let s:job = {
      \ 'id': '',
      \ 'keyword': '',
      \ 'found': v:false,
      \ 'picker': '',
      \ 'result': '',
      \ }

function! s:job.init() abort
  let self.id = ''
  let self.keyword = ''
  let self.found = v:false
  let self.picker = ''
  let self.result = []
endfunction

""" iced#grep#exe {{{

function! s:on_grep_out(_, out) abort
  if empty(s:job.id) || empty(a:out)
    return
  endif

  let ef = &errorformat
  let &errorformat = g:iced#grep#format
  try
    for line in iced#util#ensure_array(a:out)
      silent exe printf(':caddexpr "%s"', escape(line, '"|\\'))
    endfor
    let s:job.found = v:true
  finally
    let &errorformat = ef
  endtry
endfunction

function! s:on_grep_exit(_) abort
  if empty(s:job.id) | return | endif

  try
    if s:job.found
      call iced#message#info('finish_to_grep', s:job.keyword)
    else
      call iced#di#get('ex_cmd').silent_exe(':cclose')
      call iced#message#warning('grep_not_found', s:job.keyword)
    endif
  finally
    call s:job.init()
  endtry
endfunction

function! iced#grep#exe(kw) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  let user_dir = iced#nrepl#system#user_dir()
  if empty(user_dir) | return | endif

  if !empty(s:job.id)
    return iced#message#warning('grep_running')
  endif

  " NOTE: To open file from QuickFix, vim-iced changes current working directory globally.
  silent execute printf(':cd %s', user_dir)

  let kw = empty(a:kw) ? iced#nrepl#var#cword() : a:kw
  let command = g:iced#grep#prg
  if stridx(command, '$*') != -1
    let command = substitute(command, '$\*', kw, 'g')
  else
    let command = printf('%s %s', command, kw)
  endif

  call iced#message#info('start_to_grep', kw)
  call iced#di#get('quickfix').setlist([], 'r')
  call iced#di#get('ex_cmd').silent_exe(':copen')
  let s:job.keyword = kw
  let s:job.id = iced#compat#job_start(['sh', '-c', command], {
        \ 'out_cb': funcref('s:on_grep_out'),
        \ 'close_cb': funcref('s:on_grep_exit'),
        \ })
endfunction

""" }}}

""" iced#grep#live {{{

function! s:on_live_grep_out(_, out) abort
  if empty(s:job.id) || empty(a:out) || empty(s:job.picker)
    return
  endif

  if has('nvim')
    call extend(s:job.result, iced#util#ensure_array(a:out))
    call filter(s:job.result, {_, v -> !empty(v)})
  else
    call extend(s:job.result, [a:out])
  endif
endfunction

function! s:on_live_grep_exit(_) abort
  if empty(s:job.picker) | return | endif
  call quickpick#set_items(s:job.picker, copy(s:job.result))
  call s:job.init()
endfunction

function! s:on_change(id, action, data) abort
  let command = g:iced#grep#prg
  if stridx(command, '$*') != -1
    let command = substitute(command, '$\*', a:data, 'g')
  else
    let command = printf('%s "%s"', command, a:data)
  endif

  if !empty(s:job.id)
    try
      call iced#compat#job_stop(s:job.id)
    catch /E900: Invalid channel id/
      " NOTE: neovim sometimes throw this exception
    endtry
  endif

  call s:job.init()
  let s:job.picker = a:id
  let s:job.keyword = a:data
  let s:job.id = iced#compat#job_start(['sh', '-c', command], {
        \ 'out_cb': funcref('s:on_live_grep_out'),
        \ 'close_cb': funcref('s:on_live_grep_exit'),
        \ })
endfunction

function! s:on_accept(id, action, data) abort
  call quickpick#close(a:id)
  let items = map(a:data['items'], {_, v -> escape(v, '"|\\')})

  let ef = &errorformat
  let &errorformat = g:iced#grep#format
  try
    silent exe printf(':cexpr %s', items)
  finally
    let &errorformat = ef
  endtry
endfunction

function! s:is_quickpick_enabled() abort
  return (globpath(&runtimepath, 'autoload/quickpick.vim') !=# '')
endfunction

function! iced#grep#live() abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  if !iced#cache#do_once('is_quickpick_enabled', funcref('s:is_quickpick_enabled'))
    return iced#message#error('no_quickpick')
  endif

  let user_dir = iced#nrepl#system#user_dir()
  if empty(user_dir) | return | endif

  if !empty(s:job.id)
    return iced#message#warning('grep_running')
  endif

  " NOTE: To open file from QuickFix, vim-iced changes current working directory globally.
  silent execute printf(':cd %s', user_dir)

  let id = quickpick#create({
        \ 'on_change': function('s:on_change'),
        \ 'on_accept': function('s:on_accept'),
        \ 'items': [],
        \ })
  call quickpick#show(id)
endfunction

" }}}

let &cpoptions = s:save_cpo
unlet s:save_cpo
