let s:save_cpo = &cpo
set cpo&vim

function! iced#state#channel#start(params) abort
  return has('nvim')
        \ ? iced#state#channel#neovim#start(a:params)
        \ : iced#state#channel#vim#start(a:params)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
