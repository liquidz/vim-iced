let s:save_cpo = &cpoptions
set cpoptions&vim

let g:iced#popup#time = get(g:, 'iced#popup#time', 3000)
let g:iced#popup#max_height = get(g:, 'iced#popup#max_height', 50)

function! iced#component#popup#config#start(_) abort
  return {
        \ 'time': g:iced#popup#time,
        \ 'max_height': g:iced#popup#max_height,
        \ }
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
