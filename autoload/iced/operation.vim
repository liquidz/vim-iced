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

function! iced#operation#eval_and_tap(type) abort
  return s:eval({code -> iced#nrepl#eval#code(printf('(clojure.core/tap> %s)', code))})
endfunction

function! s:replace_by_response_value(resp) abort
  if has_key(a:resp, 'value')
    let @@ = printf(';; %s', a:resp['value'])
    silent normal! gvp
  endif

  if has_key(a:resp, 'ex') && !empty(a:resp['ex'])
    call iced#message#error_str(a:resp['ex'])
  endif

  call iced#nrepl#eval#err(get(a:resp, 'err', ''))
endfunction

function! iced#operation#eval_and_replace(type) abort
  return s:eval({code -> iced#nrepl#eval(
        \ iced#nrepl#eval#normalize_code(code),
        \ funcref('s:replace_by_response_value'))})
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
