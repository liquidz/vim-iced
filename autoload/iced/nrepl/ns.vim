let s:save_cpo = &cpo
set cpo&vim

let s:default_ns_favorites = {
      \ 'clj': {
      \   'clojure.edn': 'edn',
      \   'clojure.java.io': 'io',
      \   'clojure.set': 'set',
      \   'clojure.spec.alpha': 's',
      \   'clojure.spec.gen.alpha': 'sgen',
      \   'clojure.string': 'str',
      \   'clojure.walk': 'walk',
      \   'clojure.zip': 'zip',
      \   },
      \ 'cljs': {
      \   'cljs.reader': 'reader',
      \   'cljs.spec.alpha': 's',
      \   'cljs.spec.gen.alpha': 'sgen',
      \   'clojure.set': 'set',
      \   'clojure.string': 'str',
      \   'clojure.walk': 'walk',
      \   'clojure.zip': 'zip',
      \   },
      \ }
let g:iced#nrepl#ns#favorites = get(g:, 'iced#nrepl#ns#favorites', s:default_ns_favorites)

function! s:search_ns() abort
  call cursor(1, 1)
  let line = trim(getline('.'))
  if line !=# '(ns' && line[0:3] !=# '(ns '
    return search('(ns[ \r\n]')
  endif
  return 1
endfunction

function! iced#nrepl#ns#replace(new_ns) abort
  let view = winsaveview()
  let reg_save = @@

  try
    if s:search_ns() == 0
      call iced#message#error('ns_not_found')
      return
    endif
    silent normal! dab

    let new_ns = trim(a:new_ns)
    let before_lnum = len(split(@@, '\r\?\n'))
    let after_lnum = len(split(new_ns, '\r\?\n'))
    let view['lnum'] = view['lnum'] + (after_lnum - before_lnum)

    if before_lnum == 1
      call deletebufline('%', line('.'), 1)
    endif

    let lnum = line('.') - 1
    call append(lnum, split(new_ns, '\r\?\n'))
  finally
    let @@ = reg_save
    if s:search_ns() != 0
      call iced#format#form()
      call iced#nrepl#ns#eval(v:none)
    endif
    call winrestview(view)
  endtry
endfunction

function! iced#nrepl#ns#get() abort
  let view = winsaveview()
  let reg_save = @@
  let code = v:none

  try
    if s:search_ns() == 0
      return v:none
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
      \ 'id': iced#nrepl#eval#id(),
      \ 'op': 'eval',
      \ 'code': '*ns*',
      \ 'session': session,
      \ })
  if !has_key(resp, 'value')
    return v:none
  endif
  return iced#nrepl#ns#util#extract_ns(resp['value'])
endfunction

function! iced#nrepl#ns#name() abort
  let view = winsaveview()
  let reg_save = @@

  try
    if s:search_ns() == 0
      let ns_name = s:ns_name_by_var()
      if empty(ns_name)
        call iced#message#error('ns_not_found')
        return
      endif
      return ns_name
    endif
    let start = line('.')
    let line = trim(join(getline(start, start+1), ' '))
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
    call a:callback(v:none)
  else
    call iced#nrepl#eval(code, a:callback)
  endif
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
  let Cb = {_ -> iced#util#echo_messages('Required')}
  if iced#nrepl#current_session_key() ==# 'clj'
    call iced#nrepl#load_file({resp -> s:required(resp, Cb)})
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

function! iced#nrepl#ns#repl() abort
  return (iced#nrepl#current_session_key() ==# 'clj')
      \ ? 'clojure.repl'
      \ : 'cljs.repl'
endfunction

function! iced#nrepl#ns#in_repl_session_ns() abort
  let ns_name = s:ns_name_by_var(iced#nrepl#repl_session())
  if empty(ns_name)
    call iced#message#warn('not_found')
    return
  endif

  let code = printf('(in-ns ''%s)', ns_name)
  call iced#nrepl#eval#code(code)
endfunction

function! s:add_ns(ns_name) abort
  let favorites = get(g:iced#nrepl#ns#favorites, iced#nrepl#current_session_key(), {})
  if has_key(favorites, a:ns_name)
    let ns_alias = favorites[a:ns_name]
  else
    let candidate = iced#nrepl#ns#alias#find_existing_alias(a:ns_name)
    if empty(candidate)
      let candidate = ''
    endif
    let ns_alias = trim(input('Alias: ', candidate))
  endif

  let code = iced#nrepl#ns#get()
  let code = iced#nrepl#ns#util#add_require_form(code)
  let code = iced#nrepl#ns#util#add_namespace_to_require(code, a:ns_name, ns_alias)
  call iced#nrepl#ns#replace(code)

  let msg = ''
  if empty(ns_alias)
    let msg = printf(iced#message#get('ns_added'), a:ns_name)
  else
    let msg = printf(iced#message#get('ns_added_as'), a:ns_name, ns_alias)
  endif
  call iced#message#info_str(msg)
endfunction

function! s:project_namespaces(namespaces) abort
  let namespaces = (empty(a:namespaces) ? [] : a:namespaces)
  let favorites = get(g:iced#nrepl#ns#favorites, iced#nrepl#current_session_key(), {})
  call extend(namespaces, keys(favorites))

  call ctrlp#iced#start({
        \ 'candidates': namespaces,
        \ 'accept': {_, ns_name -> s:add_ns(ns_name)}
        \ })
endfunction

function! iced#nrepl#ns#add(ns_name) abort
  if empty(a:ns_name)
    call iced#nrepl#iced#project_namespaces(funcref('s:project_namespaces'))
  else
    call s:add_ns(a:ns_name)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
