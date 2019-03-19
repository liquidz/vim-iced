let s:save_cpo = &cpo
set cpo&vim

function! iced#state#bencode#definition() abort
  return {'start': has('python3') ? function('iced#state#bencode#python#start')
        \                         : function('iced#state#bencode#vim#start')}
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
