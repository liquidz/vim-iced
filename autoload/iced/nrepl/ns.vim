let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:D = s:V.import('Data.Dict')

function! iced#nrepl#ns#get() abort
  let view = winsaveview()
  let reg_save = @@
  let code = ''

  try
    if iced#nrepl#ns#util#search() == 0
      return ''
    endif
    silent normal! va(y
    let code = @@
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry

  return code
endfunction

function! s:ns_name_by_var(...) abort
  let session = get(a:, 1, iced#nrepl#current_session())
  let resp = iced#nrepl#sync#send({
      \ 'id': iced#nrepl#id(),
      \ 'op': 'eval',
      \ 'code': '*ns*',
      \ 'session': session,
      \ })
  if !has_key(resp, 'value')
    return ''
  endif
  return iced#nrepl#ns#util#extract_ns(resp['value'])
endfunction

function! iced#nrepl#ns#name() abort
  let view = winsaveview()
  let reg_save = @@

  try
    if iced#nrepl#ns#util#search() == 0
      let ns_name = s:ns_name_by_var()
      if empty(ns_name)
        call iced#message#error('ns_not_found')
        return
      endif
      return ns_name
    endif
    let start = line('.')
    let line = iced#compat#trim(join(getline(start, start+1), ' '))
    let line = substitute(line, '(ns ', '', '')
    return matchstr(line, '[a-z0-9.\-]\+',
          \ (stridx(line, '^') == 0 ? stridx(line, ' ') : 0))
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

function! iced#nrepl#ns#eval(callback) abort
  let code = iced#nrepl#ns#get()
  if empty(code)
    call a:callback('')
  else
    call iced#nrepl#eval(code, a:callback)
  endif
endfunction

function! s:cljs_load_file(callback) abort
  if !iced#nrepl#is_connected()
    return iced#message#error('not_connected')
  endif

  call iced#nrepl#send({
      \ 'op': 'eval',
      \ 'session': iced#nrepl#current_session(),
      \ 'id': iced#nrepl#id(),
      \ 'code': printf('(load-file "%s")', expand('%:p')),
      \ 'callback': a:callback,
      \ })
endfunction

function! s:required(resp, callback) abort
  if has_key(a:resp, 'error')
    return iced#nrepl#eval#err(a:resp['error'])
  elseif has_key(a:resp, 'err')
    return iced#nrepl#eval#err(a:resp['err'])
  endif
  call iced#qf#clear()
  call iced#nrepl#ns#eval(a:callback)
endfunction

function! iced#nrepl#ns#require() abort
  let Cb = {_ -> iced#message#info('required')}
  if ! iced#nrepl#check_session_validity() | return | endif

  if iced#nrepl#current_session_key() ==# 'clj'
    call iced#nrepl#load_file({resp -> s:required(resp, Cb)})
  else
    call s:cljs_load_file(Cb)
  endif
endfunction

function! iced#nrepl#ns#require_all() abort
  let Cb = {_ -> iced#message#info('all_reloaded')}
  if ! iced#nrepl#check_session_validity() | return | endif

  if iced#nrepl#current_session_key() ==# 'clj'
    let ns = iced#nrepl#ns#name()
    let code = printf('(clojure.core/require ''%s :reload-all)', ns)
    call iced#nrepl#eval(code, Cb)
  else
    call s:cljs_load_file(Cb)
  endif
endfunction

function! iced#nrepl#ns#repl() abort
  return (iced#nrepl#current_session_key() ==# 'clj')
      \ ? 'clojure.repl'
      \ : 'cljs.repl'
endfunction

function! iced#nrepl#ns#in_repl_session_ns() abort
  if iced#nrepl#current_session_key() ==# 'cljs'
    return iced#message#error('invalid_session', 'clj')
  endif

  let ns_name = s:ns_name_by_var(iced#nrepl#repl_session())
  if empty(ns_name)
    call iced#message#warn('not_found')
    return
  endif

  let code = printf('(in-ns ''%s)', ns_name)
  call iced#nrepl#eval#code(code)
endfunction

function! iced#nrepl#ns#alias_dict(ns_name) abort
  try
    let resp = iced#nrepl#op#cider#sync#ns_aliases(a:ns_name)
    return get(resp, 'ns-aliases', {})
  catch
    return {}
  endtry
endfunction

function! iced#nrepl#ns#find_existing_alias(ns_name) abort
  let aliases = iced#nrepl#op#refactor#sync#all_ns_aliases()
  let aliases = get(aliases, iced#nrepl#current_session_key(), {})

  for k in keys(aliases)
    if k ==# 'sut' | continue | endif
    for ns in aliases[k]
      if ns ==# a:ns_name
        return k
      endif
    endfor
  endfor
  return ''
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
