let s:save_cpo = &cpo
set cpo&vim

function! iced#state#channel#definition() abort
  return {'start': has('nvim') ? function('iced#state#channel#neovim#start')
        \                      : function('iced#state#channel#vim#start')}
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
