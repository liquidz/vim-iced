let s:save_cpo = &cpo
set cpo&vim

function! s:search_ns() abort
  call cursor(1, 1)
  if trim(getline('.'))[0:3] !=# '(ns '
    call search('(ns ')
  endif
endfunction

function! iced#nrepl#ns#replace(new_ns) abort
  let view = winsaveview()
  let reg_save = @@

  try
    call s:search_ns()
    silent normal! dab

    let before_lnum = len(split(@@, '\r\?\n'))
    let after_lnum = len(split(a:new_ns, '\r\?\n'))
    let view['lnum'] = view['lnum'] + (after_lnum - before_lnum)

    let lnum = line('.') - 1
    call append(lnum, split(a:new_ns, '\n'))
  finally
    let @@ = reg_save
    call s:search_ns()
    call iced#format#form()
    call iced#nrepl#ns#eval(v:none)
    call winrestview(view)
  endtry
endfunction

function! iced#nrepl#ns#get() abort
  let view = winsaveview()
  let reg_save = @@
  let code = v:none

  try
    call s:search_ns()
    silent normal! va(y
    let code = @@
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry

  return code
endfunction

function! iced#nrepl#ns#name() abort
  let view = winsaveview()
  let reg_save = @@

  try
    call s:search_ns()
    let start = line('.')
    let line = trim(join(getline(start, start+1), ' '))
    let line = substitute(line, '(ns ', '', '')
    return matchstr(line, '[a-z0-9.\-]\+')
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

function! iced#nrepl#ns#eval(callback) abort
  let code = iced#nrepl#ns#get()
  call iced#nrepl#eval(code, a:callback)
endfunction

function! s:load_file(callback) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return
  endif

  call iced#nrepl#send({
      \ 'op': 'load-file',
      \ 'session': iced#nrepl#current_session(),
      \ 'file': join(getline(1, '$'), "\n"),
      \ 'callback': a:callback,
      \ })
endfunction

function! s:cljs_load_file(callback) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return
  endif

  call iced#nrepl#send({
      \ 'op': 'eval',
      \ 'session': iced#nrepl#current_session(),
      \ 'id': iced#nrepl#eval#id(),
      \ 'code': printf('(load-file "%s")', expand('%:p')),
      \ 'callback': a:callback,
      \ })
endfunction

function! iced#nrepl#ns#require() abort
  let Cb = {_ -> iced#util#echo_messages('Required')}
  if iced#nrepl#current_session_key() ==# 'clj'
    call s:load_file({_ -> iced#nrepl#ns#eval(Cb)})
  else
    call s:cljs_load_file(Cb)
  endif
endfunction

function! iced#nrepl#ns#require_all() abort
  let Cb = {_ -> iced#util#echo_messages('All reloaded')}

  if iced#nrepl#current_session_key() ==# 'clj'
    let ns = iced#nrepl#ns#name()
    let code = printf('(clojure.core/require ''%s :reload-all)', ns)
    call iced#nrepl#eval(code, Cb)
  else
    call s:cljs_load_file(Cb)
  endif
endfunction

call iced#nrepl#register_handler('load-file')

let &cpo = s:save_cpo
unlet s:save_cpo
