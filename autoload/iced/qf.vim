let s:save_cpo = &cpo
set cpo&vim

function! iced#qf#is_opened() abort
  let ls = map(getbufinfo(), {_, v -> v['bufnr']})
  let ls = filter(ls, {_, v -> bufwinnr(v) != -1})
  let ls = filter(ls, {_, v -> getbufvar(v, '&filetype') ==# 'vim'})
  return !empty(ls)
endfunction

function! iced#qf#set(ls) abort
  call setqflist(a:ls , 'r')

  if empty(a:ls)
    cclose
    return
  endif

  if !iced#qf#is_opened()
    cwindow
  endif
  silent! doautocmd QuickFixCmdPost make
endfunction

function! iced#qf#clear() abort
  call iced#qf#set([])
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
