let s:save_cpo = &cpo
set cpo&vim

function! iced#let#jump_to_let() abort
  let view = winsaveview()
  let reg_save = @@

  try
    if iced#paredit#move_to_current_element_head() == 0
      call winrestview(view)
      return 0
    endif

    while v:true
      let head = strpart(getline('.'), col('.'), 4)
      if head ==# 'let' || head ==# 'let '
        call search('\[')
        break
      endif

      if iced#paredit#move_to_parent_element() == 0
        call winrestview(view)
        return 0
      endif
    endwhile

    return col('.')
  finally
    let @@ = reg_save
  endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
