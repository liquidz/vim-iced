let s:save_cpo = &cpo
set cpo&vim

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
    let text = trim(substitute(a:err, err, '', ''))
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

  call iced#nrepl#eval#err(get(a:resp, 'err', v:none))
endfunction

function! s:repl_out(resp) abort
  call s:out(a:resp)
  call iced#nrepl#cljs#switch_session(a:resp)
endfunction

function! iced#nrepl#eval#code(code) abort
  call iced#nrepl#eval(a:code, funcref('s:out'))
endfunction

function! iced#nrepl#eval#repl(code) abort
  call iced#nrepl#eval(a:code, funcref('s:repl_out'),
      \ {'session': 'repl'})
endfunction

function! s:undefined(symbol) abort
  call iced#message#info_str(printf(iced#message#get('undefined'), a:symbol))
endfunction

function! iced#nrepl#eval#undef(symbol) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return
  endif

  let symbol = empty(a:symbol) ? expand('<cword>') : a:symbol
  call iced#nrepl#cider#undef(symbol, {_ -> s:undefined(symbol)})
endfunction

function! iced#nrepl#eval#outer_top_list() abort
  let view = winsaveview()
  let reg_save = @@

  try
    " select current top list
    call sexp#select_current_top_list('n', 0)
    silent normal! y

    let code = @@
    if empty(code)
      echom iced#message#get('finding_code_error')
    else
      call iced#nrepl#ns#eval({_ -> iced#nrepl#eval#code(code)})
    endif
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
