let s:save_cpo = &cpo
set cpo&vim

function! iced#let#goto() abort
  let view = winsaveview()
  let reg_save = @@

  try
    call iced#paredit#move_to_prev_top_element()
    let stopline = line('.')
    call winrestview(view)
    let ret = search('(let[ \r\n]', 'b', stopline)
    if ret != 0
      call search('\[')
    endif
    return ret
  finally
    let @@ = reg_save
  endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
