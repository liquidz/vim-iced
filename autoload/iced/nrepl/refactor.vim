let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:D = s:V.import('Data.Dict')
let s:L = s:V.import('Data.List')
let s:S = s:V.import('Data.String')
" g:iced#ns#favorites {{{
let s:default_ns_favorites = {
      \ 'clj': {
      \   'clojure.edn': 'edn',
      \   'clojure.java.io': 'io',
      \   'clojure.set': 'set',
      \   'clojure.spec.alpha': 's',
      \   'clojure.spec.gen.alpha': 'sgen',
      \   'clojure.spec.test.alpha': 'stest',
      \   'clojure.string': 'str',
      \   'clojure.tools.logging': 'log',
      \   'clojure.walk': 'walk',
      \   'clojure.zip': 'zip',
      \   },
      \ 'cljs': {
      \   'cljs.reader': 'reader',
      \   'cljs.spec.alpha': 's',
      \   'cljs.spec.gen.alpha': 'sgen',
      \   'cljs.spec.test.alpha': 'stest',
      \   'clojure.set': 'set',
      \   'clojure.string': 'str',
      \   'clojure.walk': 'walk',
      \   'clojure.zip': 'zip',
      \   },
      \ }
let g:iced#ns#favorites
      \ = get(g:, 'iced#ns#favorites', s:default_ns_favorites) " }}}

" iced#nrepl#refactor#extract_function {{{
function! s:found_used_locals(resp) abort
  if !has_key(a:resp, 'used-locals')
    let msg = get(a:resp, 'error', 'Unknown error')
    return iced#message#error('used_locals_error', msg)
  endif

  let view = winsaveview()
  let reg_save = @@

  try
    let locals = a:resp['used-locals']
    let func_name = trim(iced#system#get('io').input('Function name: '))
    if empty(func_name)
      return iced#message#echom('canceled')
    endif

    let func_body = iced#paredit#get_outer_list_raw()

    let @@ = empty(locals)
          \ ? printf('(%s)', func_name)
          \ : printf('(%s %s)', func_name, join(locals, ' '))
    silent normal! gvp

    let code = printf("(defn- %s [%s]\n  %s)\n\n",
          \ func_name, join(locals, ' '),
          \ iced#util#add_indent(2, func_body))
    let codes = split(code, '\r\?\n')

    call iced#paredit#move_to_prev_top_element()
    call append(line('.')-1, codes)
    let view['lnum'] = view['lnum'] + len(codes)
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

function! iced#nrepl#refactor#extract_function() abort
  let path = expand('%:p')
  let pos = getcurpos()
  call iced#nrepl#op#refactor#find_used_locals(
        \ path, pos[1], pos[2], funcref('s:found_used_locals'))
endfunction " }}}

" iced#nrepl#refactor#clean_ns {{{
function! s:clean_ns(resp) abort
  if has_key(a:resp, 'error')
    return iced#nrepl#eval#err(a:resp['error'])
  endif
  if has_key(a:resp, 'ns')
    if empty(a:resp['ns'])
      return iced#message#info('already_clean')
    endif

    let context = iced#util#save_context()
    try
      call iced#nrepl#ns#util#replace(a:resp['ns'])
    finally
      call iced#util#restore_context(context)
    endtry
    call iced#message#info('cleaned')
  endif
endfunction

function! iced#nrepl#refactor#clean_ns() abort
  return iced#promise#call('iced#nrepl#op#refactor#clean_ns', [])
       \.then(funcref('s:clean_ns'))
endfunction " }}}

" iced#nrepl#refactor#clean_all {{{
function! iced#nrepl#refactor#clean_all() abort
  return iced#nrepl#refactor#clean_ns()
        \.then({_ -> iced#format#all()})
endfunction " }}}

" iced#nrepl#refactor#add_missing_ns {{{
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
  if len(arr) == 2 || stridx(a:symbol, '/') != -1
    return arr[0]
  endif
  return ''
endfunction

function! s:__add_missing_ns_add(ns_name, symbol_alias) abort
  call iced#nrepl#ns#util#add(a:ns_name, a:symbol_alias)
  call iced#message#info('ns_added', a:ns_name)
endfunction

function! s:__add_missing_ns_select_candidates(symbol_alias, candidates) abort
  let c = len(a:candidates)
  if c == 1
    call s:__add_missing_ns_add(a:candidates[0], a:symbol_alias)
  elseif c > 1
    call iced#selector({
       \ 'candidates': a:candidates,
       \ 'accept': {_, ns_name -> s:__add_missing_ns_add(ns_name, a:symbol_alias)}
       \ })
  else
    return iced#message#echom('no_candidates')
  endif
endfunction

function! s:__add_missing_ns_ns_alias_candidates(symbol_alias, ns_candidates, alias_dict) abort
  let candidates = copy(a:ns_candidates)
  let k = iced#nrepl#current_session_key()
  if has_key(a:alias_dict, k)
    let aliases = a:alias_dict[k]
    let names = []
    for k in filter(keys(aliases), {_, v -> stridx(v, a:symbol_alias) == 0})
      let names = names + aliases[k]
    endfor
    let names = filter(names, {_, v -> !s:L.has(candidates, v)})
    let candidates += names
  endif

  return s:__add_missing_ns_select_candidates(a:symbol_alias, candidates)
endfunction

function! s:__add_missing_ns_resolve_missing(symbol, resp) abort
  if !has_key(a:resp, 'candidates') | return | endif
  let symbol_alias = s:symbol_to_alias(a:symbol)

  if empty(a:resp['candidates'])
    let ns_candidates = []
  else
    let alias_dict = iced#nrepl#ns#alias_dict(iced#nrepl#ns#name())
    if has_key(alias_dict, symbol_alias)
      return iced#message#error('alias_exists', symbol_alias)
    endif

    let existing_ns = values(alias_dict) + ['clojure.core']
    let candidates = s:parse_candidates(a:resp['candidates'])
    let ns_candidates = filter(candidates, {_, v -> v[':type'] ==# ':ns'})
    let ns_candidates = filter(ns_candidates, {_, v -> !s:L.has(existing_ns, v[':name'])})
    let ns_candidates = map(ns_candidates, {_, v -> v[':name']})
  endif

  if empty(symbol_alias)
    return s:__add_missing_ns_select_candidates(symbol_alias, ns_candidates)
  else
    return iced#nrepl#op#refactor#all_ns_aliases({resp ->
          \ s:__add_missing_ns_ns_alias_candidates(symbol_alias, ns_candidates, resp)})
  endif
endfunction

function! s:__add_missing_by_clj_kondo_analysis(symbol) abort
  let kondo = iced#system#get('clj_kondo')
  let aliases = kondo.ns_aliases()

  let symbol_alias = s:symbol_to_alias(a:symbol)
  let ns_candidates = get(aliases, symbol_alias, [])

  return s:__add_missing_ns_select_candidates(symbol_alias, ns_candidates)
endfunction

function! iced#nrepl#refactor#add_missing_ns(symbol) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let kondo = iced#system#get('clj_kondo')
  let symbol = empty(a:symbol) ? iced#nrepl#var#cword() : a:symbol

  if kondo.is_analyzed()
    return s:__add_missing_by_clj_kondo_analysis(symbol)
  elseif iced#nrepl#is_supported_op('resolve-missing')
    call iced#nrepl#op#refactor#add_missing(symbol, {resp ->
         \ s:__add_missing_ns_resolve_missing(symbol, resp)})
  else
    return iced#message#error('not_supported')
  endif
endfunction " }}}

" iced#nrepl#refactor#add_ns {{{
function! s:__add_ns_add(ns_name, ns_alias) abort
  call iced#nrepl#ns#util#add(a:ns_name, a:ns_alias)
  return (empty(a:ns_alias)
        \ ? iced#message#info('ns_added', a:ns_name)
        \ : iced#message#info('ns_added_as', a:ns_name, a:ns_alias)
        \ )
endfunction

function! s:__add_ns_input_ns_alias(candidate) abort
  let alias = empty(a:candidate) ? '' : a:candidate
  return trim(iced#system#get('io').input('Alias: ', alias))
endfunction

function! s:__add_ns_ns_alias(ns_name) abort
  let favorites = get(g:iced#ns#favorites, iced#nrepl#current_session_key(), {})
  if has_key(favorites, a:ns_name)
    return s:__add_ns_add(a:ns_name, favorites[a:ns_name])
  else
    call iced#message#echom('fetching_ns_aliases')
    " NOTE: Use `future` because candidate is not displayed correctly in `input` for Vim
    return iced#nrepl#ns#find_existing_alias(a:ns_name, {resp ->
          \ iced#system#get('future').do({-> s:__add_ns_add(a:ns_name, s:__add_ns_input_ns_alias(resp))})
          \ })
  endif
endfunction

function! s:__add_ns_ns_list(resp) abort
  if !has_key(a:resp, 'ns-list') | return iced#message#error('ns_list_error') | endif
  let namespaces = get(a:resp, 'ns-list', [])
  let favorites = get(g:iced#ns#favorites, iced#nrepl#current_session_key(), {})
  let namespaces = s:L.uniq(s:L.concat([namespaces, keys(favorites)]))

  call iced#selector({
        \ 'candidates': namespaces,
        \ 'accept': {_, ns_name -> s:__add_ns_ns_alias(ns_name)},
        \ })
endfunction

function! iced#nrepl#refactor#add_ns(ns_name) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  if empty(a:ns_name)
    if iced#nrepl#is_supported_op('ns-list')
      call iced#nrepl#op#cider#ns_list(funcref('s:__add_ns_ns_list'))
    else
      call iced#repl#ns#list(funcref('s:__add_ns_ns_list'))
    endif
  else
    call s:__add_ns_ns_alias(a:ns_name)
  endif
endfunction " }}}

" iced#nrepl#refactor#thread_first / iced#nrepl#refactor#thread_last {{{
function! s:threading(fn) abort
  let view = winsaveview()
  let reg_save = @@

  try
    let code = iced#paredit#get_outer_list_raw()
    if !empty(code)
      let resp = a:fn(code)
      if has_key(resp, 'error')
        call iced#message#error_str(resp['error'])
      elseif has_key(resp, 'code')
        let @@ = resp['code']
        silent normal! gvp
      endif
    endif
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

function! iced#nrepl#refactor#thread_first() abort
  call s:threading({code -> iced#nrepl#op#iced#sync#refactor_thread_first(code)})
endfunction

function! iced#nrepl#refactor#thread_last() abort
  call s:threading({code -> iced#nrepl#op#iced#sync#refactor_thread_last(code)})
endfunction " }}}

" iced#nrepl#refactor#add_arity {{{
function! iced#nrepl#refactor#add_arity() abort
  let view = winsaveview()
  let reg_save = @@
  try
    let res = iced#paredit#find_parent_form_raw([
          \ 'defn', 'fn', 'defmacro', 'defmethod'])
    if !has_key(res, 'code')
      call winrestview(view)
      return iced#message#error('not_found')
    endif
    let beginning_of_defn = res['curpos']

    " Move to next element head
    silent normal! l
    call sexp#move_to_adjacent_element('n', 0, 1, 0, 0)

    " Skip metadata part
    let p = getcurpos()
    if searchpos('\^', 'cn') == [p[1], p[2]]
      call sexp#move_to_adjacent_element('n', 0, 1, 0, 0)
    endif

    let beginning_var_name = getcurpos()

    " Move to the beginning of arity
    if stridx(res['code'], '(defn') == 0 || stridx(res['code'], '(defmacro') == 0
      call sexp#move_to_adjacent_element('n', 0, 1, 0, 0)

      " Skip doc-string
      let p = getcurpos()
      if searchpos('"', 'cn') == [p[1], p[2]]
        call sexp#move_to_adjacent_element('n', 0, 1, 0, 0)
      endif

      " Skip attr-map
      let p = getcurpos()
      if searchpos('{', 'cn') == [p[1], p[2]]
        call sexp#move_to_adjacent_element('n', 0, 1, 0, 0)
      endif
    elseif stridx(res['code'], '(defmethod') == 0
      " Skip dispatch-val (move to next next element head)
      call sexp#move_to_adjacent_element('n', 2, 1, 0, 0)
    endif

    let beginning_of_arity = getcurpos()
    if searchpos('(', 'cn') == [beginning_of_arity[1], beginning_of_arity[2]]
      " For multi arity
      let @@ = "([])\n"
      silent normal! P
    else
      " For single arity
      silent normal! v
      call setpos('.', beginning_of_defn)
      silent normal! %hy
      let arity_and_body = @@
      if beginning_var_name[1] == beginning_of_arity[1]
        let @@ = printf("\n  ([])\n  (%s)", arity_and_body)
        silent normal! gvpj
      else
        let @@ = printf("([])\n  (%s)", arity_and_body)
        silent normal! gvp
      endif
    endif

    " Format new defn code
    let p = getcurpos()
    call setpos('.', beginning_of_defn)
    call iced#format#minimal({'jump_to_its_match': v:false})
    call setpos('.', beginning_var_name)
    " Move cursor to the new arity
    call search(']', 'c')
  finally
    let @@ = reg_save
  endtry
endfunction " }}}

" iced#nrepl#refactor#rename_symbol {{{
function! iced#nrepl#refactor#rename_symbol(symbol) abort
  return iced#promise#call('iced#nrepl#var#get', [a:symbol])
        \.then(funcref('s:got_var'))
endfunction

function! s:got_var(var) abort
  if !has_key(a:var, 'file')
        \|| !has_key(a:var, 'ns') || !has_key(a:var, 'name')
        \|| !has_key(a:var, 'column') || !has_key(a:var, 'line')
    return iced#message#error('not_found')
  endif

  let ns = a:var['ns']
  let name = a:var['name']
  let file = a:var['file']
  let column = a:var['column']
  let line = a:var['line']

  " find_symbol prints exception for file a jar
  if s:S.starts_with(file, 'zipfile:/')
    return iced#message#error('not_found')
  endif

  return iced#promise#call('iced#nrepl#op#refactor#find_symbol', [ns, name, file, line, column])
        \.then(funcref('s:found_symbols', [name]))
endfunction

function! s:found_symbols(old_name, symbols) abort
  let edn = iced#system#get('edn')

  let io = iced#system#get('io')
  let new_name = trim(io.input('New name: '))
  if empty(new_name)
    return iced#message#info('canceled')
  endif

  let symbols = filter(a:symbols, {i, v -> has_key(v, 'occurrence')})
  let occurrences = map(symbols, {i, v -> iced#promise#sync(edn.decode, [v['occurrence']])})

  " occurrence to the right should be renamed first to avoid shifting column numbers
  call sort(occurrences, {a, b -> b['col-beg'] - a['col-beg']}) 

  call map(occurrences, {i, v -> s:rename_occurrence(a:old_name, new_name, v)})
endfunction

function! s:char_at(expr) abort
  let [_b, cursorline, cursorcol, _o] = getpos(a:expr)
  return getline(cursorline)[cursorcol - 1]
endfunction

function! s:rename_occurrence(old_name, new_name, occurrence) abort
  let line = a:occurrence['line-beg']
  let file = a:occurrence['file']
  let column = a:occurrence['col-beg']

  let cmd = iced#system#get('ex_cmd')

  call cmd.exe(printf(':edit +%s %s', line, file))

  " navigate to the occurrence
  call cmd.exe(printf(':normal! %s|', column))

  " when occurence is definition the find-symbol reports whole form
  if s:char_at('.') ==# '('
    " skip open paren
    call cmd.exe('normal! l')
    " skip definition keyword like def defmethod defn defmulti
    call sexp#move_to_adjacent_element('n', 1, 1, 0, 0)

    " when definition has metadata
    if s:char_at('.') ==# '^'
      " skip caret symbol
      call cmd.exe('normal! l')
      " skip metadata map
      call sexp#move_to_adjacent_element('n',1, 1, 0, 0)
    endif
  endif

  " substitute exactly at position
  " \1 - matches all characters before col
  " \2 - matches optional namespace
  call cmd.exe(printf(':silent! s/\v^(.{%s})(.{-}\/)=%s/\1\2%s/', col('.') - 1, a:old_name, a:new_name))

  call cmd.exe(':write')
endfunction " }}}

let s:save_cpo = &cpo
set cpo&vim
