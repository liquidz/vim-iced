let s:save_cpo = &cpo
set cpo&vim

let g:iced#paredit#slurp_max_depth = get(g:, 'iced#paredit#slurp_max_depth', 5)

function! s:slurp(cur_pos, depth) abort
  if a:depth > g:iced#paredit#slurp_max_depth
    echo 'too deep'
  else
    let before = getcurpos()
    call sexp#stackop('n', 1, 1)
    let after = getcurpos()

    if before == after
      call sexp#move_to_nearest_bracket('n', 0)
      call sexp#move_to_nearest_bracket('n', 0)
      call s:slurp(a:cur_pos, a:depth + 1)
    else
      execute ':normal =='
      call cursor(a:cur_pos[1], a:cur_pos[2])
    endif
  endif
endfunction

function! iced#paredit#deep_slurp() abort
  let current_pos = getcurpos()
  call s:slurp(current_pos, 1)
endfunction

function! iced#paredit#barf() abort
  let current_pos = getcurpos()
  call sexp#stackop('n', 1, 0)
  call cursor(current_pos[1], current_pos[2])
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
