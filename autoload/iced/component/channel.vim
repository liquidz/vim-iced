let s:save_cpo = &cpoptions
set cpoptions&vim

function! iced#component#channel#start(this) abort
  call iced#util#debug('start', 'channel')
  if has('nvim')
    return iced#component#channel#neovim#start(a:this)
  else
    return iced#component#channel#vim#start(a:this)
  endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
