let s:save_cpo = &cpo
set cpo&vim

function! s:eval(f) abort
  let view = winsaveview()
  let reg_save = @@

  try
    silent exe 'normal! `[v`]y'
    let code = @@
    if empty(code)
      return iced#message#error('finding_code_error')
    endif
    call a:f(code)
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

function! iced#operation#eval(type) abort
  return s:eval({code -> iced#nrepl#eval#code(code)})
endfunction

function! iced#operation#eval_and_print(type) abort
  let opt = {'use-printer?': v:true}
  function! opt.callback(resp) abort
    call iced#nrepl#eval#out(a:resp)
    if has_key(a:resp, 'value')
      call iced#buffer#stdout#append(a:resp['value'])
    endif
  endfunction

  return s:eval({code -> iced#nrepl#eval#code(code, opt)})
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
