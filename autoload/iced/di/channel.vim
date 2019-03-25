let s:save_cpo = &cpo
set cpo&vim

function! iced#di#channel#build(container) abort
  if has('nvim')
    return iced#di#channel#neovim#build(a:container)
  else
    return iced#di#channel#vim#build(a:container)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
