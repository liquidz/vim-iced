let s:save_cpo = &cpo
set cpo&vim

function! s:replace_ns(resp) abort
  if has_key(a:resp, 'ns') && !empty(a:resp['ns'])
    call iced#nrepl#ns#replace(a:resp['ns'])
  endif
endfunction

function! iced#nrepl#refactor#clean_ns() abort
  let path = expand('%:p')
  call iced#nrepl#send({
      \ 'op': 'clean-ns',
      \ 'path': path,
      \ 'sesion': iced#nrepl#current_session(),
      \ 'callback': funcref('s:replace_ns'),
      \ })
endfunction

call iced#nrepl#register_handler('clean-ns')

let &cpo = s:save_cpo
unlet s:save_cpo
