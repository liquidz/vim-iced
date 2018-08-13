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
  if empty(err)
    call iced#message#error_str(a:err)
  else
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
endfunction

function! s:out(resp) abort
  if has_key(a:resp, 'value')
    echo a:resp['value']
  endif

  call iced#nrepl#eval#err(get(a:resp, 'err', v:none))
endfunction

function! iced#nrepl#eval#code(code) abort
  call iced#nrepl#eval(a:code, funcref('s:out'))
endfunction

function! iced#nrepl#eval#repl(code) abort
  call iced#nrepl#eval(a:code, funcref('s:out'),
      \ {'session': 'repl'})
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
