let s:save_cpo = &cpoptions
set cpoptions&vim

function! iced#repl#auto#bufwritepost() abort
  " clj-kondo auto analyzing
  call iced#system#get('clj_kondo').analyze({-> iced#util#debug('clj-kondo', 'analyzed')})
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
