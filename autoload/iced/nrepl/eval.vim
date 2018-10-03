let s:save_cpo = &cpo
set cpo&vim

let g:iced#nrepl#eval#inside_comment = get(g:, 'iced#nrepl#eval#inside_comment', v:true)

let s:id_counter = 1

function! iced#nrepl#eval#id() abort
  let res = s:id_counter
  let s:id_counter = (res < 100) ? res + 1 : 1
  return res
endfunction

function! iced#nrepl#eval#err(err) abort
  if empty(a:err)
    return iced#qf#clear()
  endif

  let err = matchstr(a:err, ':(.\+:\d\+:\d\+)')
  if !empty(err)
    let text = iced#compat#trim(substitute(a:err, err, '', ''))
    let err = err[2:len(err)-2]
    let arr = split(err, ':')

    let info = {
        \ 'filename': arr[0],
        \ 'lnum': arr[1],
        \ 'text': text,
        \ }

    call iced#qf#set([info])
  endif

  call iced#message#error_str(a:err)
endfunction

function! s:out(resp) abort
  if has_key(a:resp, 'value')
    echo a:resp['value']
  endif

  if has_key(a:resp, 'ex') && !empty(a:resp['ex'])
    call iced#message#error_str(a:resp['ex'])
  endif

  call iced#nrepl#eval#err(get(a:resp, 'err', ''))
endfunction

function! s:repl_out(resp) abort
  call s:out(a:resp)
  call iced#nrepl#cljs#switch_session(a:resp)
endfunction

function! s:is_comment_form(code) abort
  return (stridx(a:code, '(comment') == 0)
endfunction

function! s:extract_inside_form(code) abort
  let i = strridx(a:code, ')')
  if i != -1
    " NOTE: 8 = len('(comment')
    return iced#compat#trim(a:code[8:i-1])
  endif
  return a:code
endfunction

function! iced#nrepl#eval#code(code, ...) abort
  let view = winsaveview()
  let reg_save = @@
  let opt = get(a:, 1, {})

  let code = a:code
  if g:iced#nrepl#eval#inside_comment && s:is_comment_form(code)
    let code = s:extract_inside_form(code)
  endif

  try
    call iced#nrepl#ns#eval({_ -> iced#nrepl#eval(code, funcref('s:out'), opt)})
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

function! iced#nrepl#eval#repl(code) abort
  call iced#nrepl#eval(a:code, funcref('s:repl_out'),
      \ {'session': 'repl'})
endfunction

function! s:undefined(resp, symbol) abort
  if iced#util#has_status(a:resp, 'undef-error')
    if has_key(a:resp, 'pp-stacktrace')
      let first_stacktrace = a:resp['pp-stacktrace'][0]
      call iced#message#error_str(get(first_stacktrace, 'message', 'undef-error'))
    else
      call iced#message#error_str(get(a:resp, 'ex', 'undef-error'))
    endif
  else
    call iced#message#info_str(printf(iced#message#get('undefined'), a:symbol))
  endif
endfunction

function! iced#nrepl#eval#undef(symbol) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let symbol = empty(a:symbol) ? expand('<cword>') : a:symbol
  call iced#nrepl#op#cider#undef(symbol, {resp -> s:undefined(resp, symbol)})
endfunction

function! s:print_last(resp) abort
  if has_key(a:resp, 'pprint-out') && !empty(a:resp['pprint-out'])
    call iced#buffer#stdout#append(a:resp['pprint-out'])
  endif
endfunction

function! iced#nrepl#eval#print_last() abort
  call iced#nrepl#op#cider#pprint_eval('*1', funcref('s:print_last'))
endfunction

function! iced#nrepl#eval#outer_top_list() abort
  let ret = iced#paredit#get_current_top_list()
  let code = ret['code']
  if empty(code)
    echom iced#message#get('finding_code_error')
  else
    let pos = ret['curpos']
    let opt = {'line': pos[1], 'column': pos[2]}
    call iced#nrepl#ns#eval({_ -> iced#nrepl#eval#code(code, opt)})
  endif
endfunction

function! iced#nrepl#eval#ns() abort
  let ns_code = iced#nrepl#ns#get()
  call iced#nrepl#eval#code(ns_code)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
