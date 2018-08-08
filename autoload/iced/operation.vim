let s:save_cpo = &cpo
set cpo&vim

function! iced#operation#eval(type) abort
  let view = winsaveview()
  let reg_save = @@
  let code = v:none

  try
    silent exe 'normal! `[v`]y'
    let code = @@
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry

  if empty(code)
    echom iced#message#get('finding_code_error')
  else
    call iced#nrepl#ns#eval({x -> iced#nrepl#eval#code(code)})
  endif
endfunction

function! iced#operation#macroexpand(type) abort
  let view = winsaveview()
  let reg_save = @@
  let code = v:none

  try
    silent exe 'normal! `[v`]y'
    let code = @@
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry

  if empty(code)
    echom iced#message#get('finding_code_error')
  else
    call iced#nrepl#macro#expand(code)
  endif
endfunction

function! iced#operation#macroexpand_1(type) abort
  let view = winsaveview()
  let reg_save = @@
  let code = v:none

  try
    silent exe 'normal! `[v`]y'
    let code = @@
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry

  if empty(code)
    echom iced#message#get('finding_code_error')
  else
    call iced#nrepl#macro#expand_1(code)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
