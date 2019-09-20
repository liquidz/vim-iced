let s:save_cpo = &cpoptions
set cpoptions&vim

let g:iced#grep#prg = get(g:, 'iced#grep#prg', 'git grep --no-index -I --line-number --no-color')
let g:iced#grep#format = get(g:, 'iced#grep#format', '%f:%l:%m,%f:%l%m,%f  %l%m')

let s:job = {
      \ 'id': '',
      \ 'keyword': '',
      \ 'found': v:false,
      \ }

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
    let s:job.id = ''
    let s:job.keyword = ''
    let s:job.found = v:false
  endtry
endfunction

function! iced#grep#exe(kw) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  let user_dir = iced#nrepl#system#user_dir()
  if empty(user_dir) | return | endif

  if !empty(s:job.id)
    " already running
    return
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
  let s:job.id = iced#di#get('job').start(['sh', '-c', command], {
        \ 'out_cb': funcref('s:on_grep_out'),
        \ 'close_cb': funcref('s:on_grep_exit'),
        \ })
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
