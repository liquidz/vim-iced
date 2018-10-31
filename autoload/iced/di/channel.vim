let s:save_cpo = &cpo
set cpo&vim

function! iced#di#channel#build() abort
  if has('nvim')
    return iced#di#channel#neovim#build()
  else
    return iced#di#channel#vim#build()
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
