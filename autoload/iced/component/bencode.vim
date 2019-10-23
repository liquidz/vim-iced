let s:save_cpo = &cpoptions
set cpoptions&vim

function! iced#component#bencode#new(this) abort
  return has('python3')
        \ ? iced#component#bencode#python#new(a:this)
        \ : a:this.vim_bencode
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
