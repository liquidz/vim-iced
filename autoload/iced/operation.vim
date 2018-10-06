let s:save_cpo = &cpo
set cpo&vim

function! iced#operation#eval(type) abort
  let view = winsaveview()
  let reg_save = @@

  try
    silent exe 'normal! `[v`]y'
    let code = @@
    if empty(code)
      return iced#message#error('finding_code_error')
    endif
    call iced#nrepl#eval#code(code)
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

function! iced#operation#eval_repl(type) abort
  let view = winsaveview()
  let reg_save = @@

  try
    silent exe 'normal! `[v`]y'
    let code = @@
    if empty(code)
      return iced#message#error('finding_code_error')
    endif
    call iced#nrepl#eval#repl(code)
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

function! iced#operation#macroexpand(type) abort
  let view = winsaveview()
  let reg_save = @@

  try
    silent exe 'normal! `[v`]y'
    let code = @@
    if empty(code)
      return iced#message#error('finding_code_error')
    endif
    call iced#nrepl#macro#expand(code)
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

function! iced#operation#macroexpand_1(type) abort
  let view = winsaveview()
  let reg_save = @@

  try
    silent exe 'normal! `[v`]y'
    let code = @@
    if empty(code)
      return iced#message#error('finding_code_error')
    endif
    call iced#nrepl#macro#expand_1(code)
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
