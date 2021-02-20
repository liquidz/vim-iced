let s:save_cpo = &cpoptions
set cpoptions&vim

function! iced#component#nop#start(_) abort
  call iced#util#debug('start', 'nop')

  return {'__nop__': v:true}
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
