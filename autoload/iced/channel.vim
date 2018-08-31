let s:save_cpo = &cpo
set cpo&vim

function! iced#channel#new() abort
  return iced#channel#vim#new()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
