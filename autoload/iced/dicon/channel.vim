let s:save_cpo = &cpo
set cpo&vim

function! iced#dicon#channel#build() abort
  if has('nvim')
    return iced#dicon#channel#neovim#build()
  else
    return iced#dicon#channel#vim#build()
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
