let s:save_cpo = &cpo
set cpo&vim

function! iced#format() abort
  if !iced#nrepl#is_connected()
    silent exe "normal \<Plug>(sexp_indent)"
    return
  endif

  let current_pos = getcurpos()
  let reg_save = @@
  try
    silent exe "normal \<Plug>(sexp_move_to_prev_bracket)"
    silent normal! va(y
    let code = @@
    let formatted = iced#nrepl#format#code(code)
    if !empty(formatted)
      let @@ = formatted
      silent normal! gvp
    endif
  finally
    let @@ = reg_save
    call cursor(current_pos[1], current_pos[2])
  endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
