let s:save_cpo = &cpo
set cpo&vim

function! iced#di#bencode#build(container) abort
  return has('python3')
        \ ? iced#di#bencode#python#build(a:container)
        \ : iced#di#bencode#vim#build(a:container)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
