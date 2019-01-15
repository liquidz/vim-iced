let s:save_cpo = &cpo
set cpo&vim

function! iced#di#bencode#build() abort
  return has('python3')
        \ ? iced#di#bencode#python#build()
        \ : iced#di#bencode#vim#build()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
