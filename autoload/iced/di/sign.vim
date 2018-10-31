let s:save_cpo = &cpo
set cpo&vim

function! iced#di#sign#build() abort
  return iced#di#sign#vim#build()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
