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
    let res = iced#paredit#get_current_top_list_raw()
    let code = res['code']
    if empty(code)
      call iced#message#warning('finding_code_error')
    else
      let resp = iced#nrepl#iced#sync#format_code(code, g:iced#format#rule)
      if has_key(resp, 'formatted') && !empty(resp['formatted'])
        let @@ = resp['formatted']
        silent normal! gvp
      elseif has_key(resp, 'error')
        call iced#message#error_str(resp['error'])
      endif
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
    " NOTE: vim-sexp's slurp move cursor to tail of form
    normal! %
    let ncol = getcurpos()[2]
    silent normal! va(y
    let code = @@

    let resp = iced#nrepl#iced#sync#format_code(code, g:iced#format#rule)
    if has_key(resp, 'formatted') && !empty(resp['formatted'])
      let @@ = s:add_indent(ncol-1, resp['formatted'])
      silent normal! gvp
    endif
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
