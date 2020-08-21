let s:save_cpo = &cpoptions
set cpoptions&vim

function! iced#repl#auto#bufwritepost() abort
  " clj-kondo auto analyzing
  call iced#system#get('clj_kondo').analyze({-> ''})
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
