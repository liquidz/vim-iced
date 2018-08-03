let s:save_cpo = &cpo
set cpo&vim

function! s:search_ns() abort
  call cursor(1, 1)
  if trim(getline('.'))[0:3] !=# '(ns '
    call search('(ns ')
  endif
endfunction

function! iced#nrepl#ns#replace(new_ns) abort
  let current_pos = getcurpos()
  let reg_save = @@

  try
    call s:search_ns()
    silent normal! dab
    let lnum = line('.') - 1
    call append(lnum, split(a:new_ns, '\n'))
  finally
    let @@ = reg_save
    call cursor(current_pos[1], current_pos[2])
  endtry
endfunction

function! iced#nrepl#ns#name() abort
  let current_pos = getcurpos()
  let reg_save = @@

  try
    call s:search_ns()
    let start = line('.')
    let line = trim(join(getline(start, start+1), ' '))
    let line = substitute(line, '(ns ', '', '')
    return matchstr(line, '[a-z0-9.\-]\+')
  finally
    let @@ = reg_save
    call cursor(current_pos[1], current_pos[2])
  endtry
endfunction

function! iced#nrepl#ns#eval(callback) abort
  let current_pos = getcurpos()
  let reg_save = @@

  try
    call s:search_ns()
    silent normal! va(y
    call iced#nrepl#eval(@@, a:callback)
  finally
    let @@ = reg_save
    call cursor(current_pos[1], current_pos[2])
  endtry
endfunction

function! iced#nrepl#ns#require_all() abort
  let ns = iced#nrepl#ns#name()
  let code = printf('(clojure.core/require ''%s :reload-all)', ns)
  call iced#nrepl#eval(code, {_ -> iced#util#echo_messages('Required')})
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
