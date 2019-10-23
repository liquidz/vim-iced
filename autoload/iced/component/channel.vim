let s:save_cpo = &cpoptions
set cpoptions&vim

function! iced#component#channel#new(this) abort
  if has('nvim')
    return iced#component#channel#neovim#new(a:this)
  else
    return iced#component#channel#vim#new(a:this)
  endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
