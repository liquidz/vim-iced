let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:D = s:V.import('Data.Dict')
let s:L = s:V.import('Data.List')

function! s:replace_ns(resp) abort
  if has_key(a:resp, 'error')
    return iced#nrepl#eval#err(a:resp['error'])
  endif
  if has_key(a:resp, 'ns') && !empty(a:resp['ns'])
    call iced#nrepl#ns#replace(a:resp['ns'])
    call iced#message#info('cleaned')
  endif
endfunction

function! iced#nrepl#refactor#clean_ns() abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return
  else
    let path = expand('%:p')
    call iced#nrepl#send({
        \ 'op': 'clean-ns',
        \ 'path': path,
        \ 'sesion': iced#nrepl#current_session(),
        \ 'callback': funcref('s:replace_ns'),
        \ })
  endif
endfunction

function! s:parse_candidates(candidates) abort
  let res = []
  for candidate in split(substitute(a:candidates, '[(),{]', '', 'g'), '} \?')
    let x = s:D.from_list(split(candidate, ' \+'))
    call add(res, x)
  endfor
  " ex. [{':type': ':ns', ':name': 'clojure.set'}, {':type': ':ns', ':name': 'clojure.string'}]
  return res
endfunction

function! s:symbol_to_alias(symbol) abort
  let arr = split(a:symbol, '/')
  if len(arr) == 2
    return arr[0]
  endif
  return v:none
endfunction

function! s:add_ns(ns_name, symbol_alias) abort
  let ns_alias = a:symbol_alias
  if a:ns_name ==# a:symbol_alias
    let ns_alias = v:none
  endif

  let code = iced#nrepl#ns#get()
  let code = iced#nrepl#ns#util#add_require_form(code)
  let code = iced#nrepl#ns#util#add_namespace_to_require(code, a:ns_name, ns_alias)
  call iced#nrepl#ns#replace(code)
  call iced#message#info_str(printf(iced#message#get('ns_added'), a:ns_name))
endfunction

function! s:resolve_missing(symbol, resp) abort
  if !has_key(a:resp, 'candidates')
    return
  endif

  let symbol_alias = s:symbol_to_alias(a:symbol)
  let ns_form = iced#nrepl#ns#get()
  let alias_dict = iced#nrepl#ns#alias#dict_from_code(ns_form)
  if has_key(alias_dict, symbol_alias)
    echom printf(iced#message#get('alias_exists'), symbol_alias)
    return
  endif

  let existing_ns = values(alias_dict) + ['clojure.core']
  let candidates = s:parse_candidates(a:resp['candidates'])
  let ns_candidates = filter(candidates, {_, v -> v[':type'] ==# ':ns'})
  let ns_candidates = filter(ns_candidates, {_, v -> !s:L.has(existing_ns, v[':name'])})
  let ns_candidates = map(ns_candidates, {_, v -> v[':name']})

  let c = len(ns_candidates)
  if c == 1
    call s:add_ns(ns_candidates[0], symbol_alias)
  elseif c > 1
    call ctrlp#iced#start({
        \ 'candidates': ns_candidates,
        \ 'accept': {_, ns_name -> s:add_ns(ns_name, symbol_alias)}
        \ })
  else
    echom iced#message#get('no_candidates')
  endif
endfunction

function! iced#nrepl#refactor#add_missing(symbol) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return
  else
    let symbol = empty(a:symbol) ? expand('<cword>') : a:symbol
    call iced#message#echom('resolving_missing')
    call iced#nrepl#send({
        \ 'op': 'resolve-missing',
        \ 'symbol': symbol,
        \ 'sesion': iced#nrepl#current_session(),
        \ 'callback': {resp -> s:resolve_missing(symbol, resp)},
        \ })
  endif
endfunction

call iced#nrepl#register_handler('clean-ns')
call iced#nrepl#register_handler('resolve-missing')

let &cpo = s:save_cpo
unlet s:save_cpo
