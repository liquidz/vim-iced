let s:save_cpo = &cpo
set cpo&vim

" NOTE: used in iced/nrepl/format.vim
let g:iced#format#rule = get(g:, 'iced#format#rule', {})

function! iced#format#form() abort
  if !iced#nrepl#is_connected()
    silent exe "normal \<Plug>(sexp_indent)"
    return
  endif

  let view = winsaveview()
  let reg_save = @@
  try
    " move to the start position of current paragraph
    silent normal! {j
    if line('.') >= view['lnum']
      let tmp = copy(view)
      let tmp['lnum'] = view['lnum'] - 1
      let tmp['col'] = 0
      silent call winrestview(tmp)
    endif

    " select current top list
    call sexp#select_current_top_list('n', 0)
    " yank
    silent normal! y
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
    call winrestview(view)
  endtry
endfunction

function! s:add_indent(n, s) abort
  let spc = ''
  for _ in range(a:n) | let spc = spc . ' ' | endfor
  return substitute(a:s, '\r\?\n', "\n".spc, 'g')
endfunction

function! iced#format#minimal() abort
  if !iced#nrepl#is_connected()
    silent exe "normal \<Plug>(sexp_indent)"
    return
  endif

  let view = winsaveview()
  let reg_save = @@
  try
    call sexp#move_to_nearest_bracket('n', 0)
    let ncol = getcurpos()[2]
    silent normal! va(y
    let code = @@
    let formatted = iced#nrepl#format#code(code)
    if !empty(formatted)
      let @@ = s:add_indent(ncol-1, formatted)
      silent normal! gvp
    endif
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
