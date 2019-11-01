let s:save_cpo = &cpoptions
set cpoptions&vim

function! iced#component#bencode#start(this) abort
  call iced#util#debug('start', 'bencode')
  return has('python3')
        \ ? iced#component#bencode#python#start(a:this)
        \ : a:this.vim_bencode
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
