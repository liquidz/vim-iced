let s:save_cpo = &cpoptions
set cpoptions&vim

let g:iced#popup#time = get(g:, 'iced#popup#time', 3000)
let g:iced#popup#max_height = get(g:, 'iced#popup#max_height', 50)

function! iced#di#popup#build(container) abort
  return has('nvim')
        \ ? iced#di#popup#neovim#build(a:container)
        \ : iced#di#popup#vim#build(a:container)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
