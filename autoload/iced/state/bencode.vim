let s:save_cpo = &cpo
set cpo&vim

function! iced#state#bencode#start(params) abort
  return has('python3')
        \ ? iced#state#bencode#python#start(a:params)
        \ : iced#state#bencode#vim#start(a:params)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
