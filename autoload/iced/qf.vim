let s:save_cpo = &cpo
set cpo&vim

let g:iced#qf#height = get(g:, 'iced#qf#height', 5)

function! iced#qf#is_opened() abort
  let ls = map(getbufinfo(), {_, v -> v['bufnr']})
  let ls = filter(ls, {_, v -> bufwinnr(v) != -1})
  let ls = filter(ls, {_, v -> getbufvar(v, '&filetype') ==# 'vim'})
  return !empty(ls)
endfunction

function! iced#qf#set(ls) abort
  call iced#di#get('quickfix').setlist(a:ls, 'r')

  if empty(a:ls)
    call iced#state#get('ex_cmd').silent_exe(':cclose')
    return
  endif

  silent! doautocmd QuickFixCmdPost vim-iced
endfunction

function! iced#qf#clear() abort
  call iced#qf#set([])
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
