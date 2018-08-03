let s:save_cpo = &cpo
set cpo&vim

let s:id_counter = 1

function! iced#nrepl#eval#id() abort
  let res = s:id_counter
  let s:id_counter = (res < 100) ? res + 1 : 1
  return res
endfunction

function! s:clear_err() abort
  call setqflist([] , 'r')
  cclose
endfunction

function! s:err(err) abort
  let err = matchstr(a:err, ':(.\+:\d\+:\d\+)')
  if empty(err)
    call iced#util#echo_messages(a:err)
  else
    let text = trim(substitute(a:err, err, '', ''))
    let err = err[2:len(err)-2]
    let arr = split(err, ':')

    let info = {
        \ 'filename': arr[0],
        \ 'lnum': arr[1],
        \ 'text': text,
        \ }

    call setqflist([info] , 'r')
    cwindow
    silent! doautocmd QuickFixCmdPost make
  endif
endfunction

function! s:out(resp) abort
  if has_key(a:resp, 'value')
    echo a:resp['value']
  endif

  if has_key(a:resp, 'err')
    call s:err(a:resp['err'])
  else
    call s:clear_err()
  endif
endfunction

function! iced#nrepl#eval#code(code) abort
  call iced#nrepl#eval(a:code, funcref('s:out'))
endfunction

function! iced#nrepl#eval#repl(code) abort
  call iced#nrepl#eval(a:code, funcref('s:out'), 'repl')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
