let s:save_cpo = &cpoptions
set cpoptions&vim

let g:iced#popup#time = get(g:, 'iced#popup#time', 3000)
let g:iced#popup#max_height = get(g:, 'iced#popup#max_height', 50)

function! iced#component#popup#start(this) abort
  call iced#util#debug('start', 'popup')
  return has('nvim')
        \ ? iced#component#popup#neovim#start(a:this)
        \ : iced#component#popup#vim#start(a:this)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
