let s:save_cpo = &cpoptions
set cpoptions&vim

function! iced#di#popup#build(container) abort
  return has('nvim')
        \ ? iced#di#popup#neovim#build(a:container)
        \ : iced#di#popup#vim#build(a:container)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
