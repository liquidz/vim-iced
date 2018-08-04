let s:save_cpo = &cpo
set cpo&vim

" NOTE: used in iced/nrepl/format.vim
let g:iced#format#rule = get(g:, 'iced#format#rule', {})

function! iced#format#form() abort
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
    if code[0] !=# '('
      exe "normal! \<Esc>"
      return
    endif

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
