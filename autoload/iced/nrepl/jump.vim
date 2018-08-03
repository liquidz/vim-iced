let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('iced')
let s:L = s:V.import('Data.List')

let s:tagstack = []
" FIXME
"let s:limit = 10

function! s:jump(resp) abort
  let path = substitute(a:resp['file'], '^file:', '', '')
  let line = a:resp['line']
  let column = a:resp['column']

  if expand('%:p') !=# path
    execute(printf(':edit %s', path))
  endif

  call cursor(line, column)
endfunction

function! iced#nrepl#jump#jump(symbol) abort
  let pos = getcurpos()
  let pos[0] = bufnr('%')
  call s:L.push(s:tagstack, pos)

  let kw = empty(a:symbol) ? expand('<cword>') : a:symbol
  call iced#nrepl#cider#info(kw, function('s:jump'))
endfunction

function! iced#nrepl#jump#back() abort
  if empty(s:tagstack)
    echo 'Local tag stack is empty'
  else
    let last_position = s:L.pop(s:tagstack)
    execute printf(':buffer %d', last_position[0])
    call cursor(last_position[1], last_position[2])
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
