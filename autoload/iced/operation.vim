let s:save_cpo = &cpo
set cpo&vim

let s:register = ''

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

function! s:yank_and_out(resp) abort
  let value = get(a:resp, 'value', '')
  if ! empty(value)
    call setreg(s:register, value)
  endif
  return iced#nrepl#eval#out(a:resp)
endfunction

function! iced#operation#eval(type) abort
  let opt = {}
  if s:register !=# '"'
    let opt['callback'] = funcref('s:yank_and_out')
  endif
  return s:eval({code -> iced#repl#execute('eval_code', code, opt)})
endfunction

function! iced#operation#setup(func_name) abort
  let &operatorfunc = a:func_name
  let s:register = v:register
endfunction

function! s:__eval_and_print(resp) abort
  call iced#nrepl#eval#out(a:resp)
  if has_key(a:resp, 'value')
    call iced#buffer#stdout#append(a:resp['value'])
  endif
endfunction

function! iced#operation#eval_and_print(type) abort
  let opt = {
        \ 'use-printer?': v:true,
        \ 'callback': funcref('s:__eval_and_print'),
        \}
  return s:eval({code -> iced#nrepl#eval#code(code, opt)})
endfunction

function! iced#operation#eval_and_tap(type) abort
  return s:eval({code -> iced#repl#execute('eval_code', printf('(clojure.core/tap> %s)', code))})
endfunction

function! s:replace_by_response_value(resp) abort
  if has_key(a:resp, 'value')
    let @@ = printf(';; %s', a:resp['value'])
		silent normal! gv"0p
  endif

  if has_key(a:resp, 'ex') && !empty(a:resp['ex'])
    call iced#message#error_str(a:resp['ex'])
  endif

  call iced#nrepl#eval#err(get(a:resp, 'err', ''))
endfunction

function! iced#operation#eval_and_replace(type) abort
  return s:eval({code -> iced#repl#execute(
        \ 'eval_raw',
        \ iced#nrepl#eval#normalize_code(code),
        \ funcref('s:replace_by_response_value'))})
endfunction

function! iced#operation#eval_and_comment(type) abort
  let opt = {'callback': funcref('s:__eval_and_comment')}
  return s:eval({code -> iced#nrepl#eval#code(code, opt)})
endfunction

function! s:__eval_and_comment(resp) abort
  if has_key(a:resp, 'value')
    let lnum = line('.')
    let line = getline(lnum)
    if line =~# ';; => .\+$'
      let idx = strridx(line, ';; => ')
      call setline(lnum, printf('%s;; => %s', line[0:idx-1], a:resp['value']))
    else
      call setline(lnum, printf('%s ;; => %s', line, a:resp['value']))
    endif
  endif
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
