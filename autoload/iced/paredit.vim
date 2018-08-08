let s:save_cpo = &cpo
set cpo&vim

let g:iced#paredit#slurp_max_depth = get(g:, 'iced#paredit#slurp_max_depth', 5)

function! s:slurp(current_view, depth) abort
  if a:depth > g:iced#paredit#slurp_max_depth
    echom iced#message#get('too_deep_to_slurp')
  else
    let before = getcurpos()
    call sexp#stackop('n', 1, 1)
    let after = getcurpos()

    if before == after
      call sexp#move_to_nearest_bracket('n', 0)
      call sexp#move_to_nearest_bracket('n', 0)
      call s:slurp(a:current_view, a:depth + 1)
    else
      execute ':normal =='
      call winrestview(a:current_view)
    endif
  endif
endfunction

function! iced#paredit#deep_slurp() abort
  call s:slurp(winsaveview(), 1)
endfunction

function! iced#paredit#barf() abort
  let view = winsaveview()
  call sexp#stackop('n', 1, 0)
  call winrestview(view)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
