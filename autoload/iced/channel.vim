let s:save_cpo = &cpo
set cpo&vim

function! iced#channel#new() abort
  if has('nvim')
    return iced#channel#neovim#new()
  else
    return iced#channel#vim#new()
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
