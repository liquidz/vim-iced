let s:save_cpo = &cpo
set cpo&vim

function! iced#dicon#sign#build() abort
  return iced#dicon#sign#vim#build()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
