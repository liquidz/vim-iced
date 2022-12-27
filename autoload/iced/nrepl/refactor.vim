let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:D = s:V.import('Data.Dict')
let s:L = s:V.import('Data.List')
" g:iced#ns#favorites {{{
let s:default_ns_favorites = {
      \ 'clj': {
      \   'cheshire.core': 'json',
      \   'clj-http.client': 'http',
      \   'clj-yaml.core': 'yaml',
      \   'clojure.core.async': 'as',
      \   'clojure.core.matrix': 'mat',
      \   'clojure.data.csv': 'csv',
      \   'clojure.data.xml': 'xml',
      \   'clojure.edn': 'edn',
      \   'clojure.java.io': 'io',
      \   'clojure.java.shell': 'sh',
      \   'clojure.pprint': 'pp',
      \   'clojure.set': 'set',
      \   'clojure.spec.alpha': 'spec',
      \   'clojure.spec.gen.alpha': 'sgen',
      \   'clojure.spec.test.alpha': 'stest',
      \   'clojure.string': 'str',
      \   'clojure.tools.logging': 'log',
      \   'clojure.walk': 'walk',
      \   'clojure.zip': 'zip',
      \   'hugsql.core': 'sql',
      \   'java-time': 'time',
      \   },
      \ 'cljs': {
      \   'cljs.core.async': 'as',
      \   'cljs.pprint': 'pp',
      \   'cljs.reader': 'reader',
      \   'cljs.spec.alpha': 'spec',
      \   'cljs.spec.gen.alpha': 'sgen',
      \   'cljs.spec.test.alpha': 'stest',
      \   'clojure.edn': 'edn',
      \   'clojure.set': 'set',
      \   'clojure.string': 'str',
      \   'clojure.walk': 'walk',
      \   'clojure.zip': 'zip',
      \   },
      \ }
let g:iced#ns#favorites
      \ = get(g:, 'iced#ns#favorites', s:default_ns_favorites) " }}}
let g:iced#ns#class_map = get(g:, 'iced#ns#class_map', {})

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
    silent normal! gv"0p

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
function! s:unify_ns_form() abort
  " NOTE:
  " When g:iced#refactor#insert_newline_after_require is true,
  " refactor-nrepl's clean-ns op returns ns form including newline after require.
  " But if there are no changes in ns form, clean-ns op returns empty string as ns.
  " Thus, when there is no newline after require and there are no changes in ns form,
  " the newline after require won't be added.
  "
  " To unify these behaviors, even if there are no changes in ns form,
  " vim-iced will add a newline after require while
  " g:iced#refactor#insert_newline_after_require is true.
  "
  " cf. https://github.com/liquidz/vim-iced/issues/453
  if ! g:iced#refactor#insert_newline_after_require
    return v:false
  endif

  let ns_form = iced#nrepl#ns#get()
  let idx = stridx(ns_form, ':require')
  if idx == -1
    return v:false
  endif

  let idx = idx + len(':require')
  if ns_form[idx] !=# ' '
    return v:false
  endif

  let new_ns_form = printf("%s\n%s", trim(strpart(ns_form, 0, idx)), trim(strpart(ns_form, idx)))
  let context = iced#util#save_context()
  try
    call iced#nrepl#ns#util#replace(new_ns_form)
  finally
    call iced#util#restore_context(context)
  endtry

  return v:true
endfunction

function! s:clean_ns(resp) abort
  if has_key(a:resp, 'error')
    return iced#nrepl#eval#err(a:resp['error'])
  endif
  if has_key(a:resp, 'ns')
    if empty(a:resp['ns'])
      if s:unify_ns_form()
        return iced#message#info('already_clean_but_reform')
      else
        return iced#message#info('already_clean')
      endif
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
  let symbol = substitute(a:symbol, '^:\+', '', 'g')
  let arr = split(symbol, '/')
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
    call iced#message#echom('no_candidates')
    return v:false
  endif

  return v:true
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

function! s:__add_missing_java_class_select_candidates(resp) abort
  let candidates = get(a:resp, 'candidates', [])
  if empty(candidates)
    return iced#message#error('not_found')
  endif

  if len(candidates) == 1
    return iced#nrepl#ns#util#add_class(candidates[0])
  else
    return iced#selector({
          \ 'candidates': candidates,
          \ 'accept': {_, class_name -> iced#nrepl#ns#util#add_class(class_name)}
          \ })
  endif
endfunction

function! iced#nrepl#refactor#add_missing_ns(symbol) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let kondo = iced#system#get('clj_kondo')
  let symbol = empty(a:symbol) ? iced#nrepl#var#cword() : a:symbol
  let c = char2nr(symbol)

  if c >= 65 && c <= 90
    return iced#promise#call('iced#nrepl#op#iced#java_class_candidates', [symbol, g:iced#ns#class_map])
         \.then(funcref('s:__add_missing_java_class_select_candidates'))
  endif

  let added = v:false
  if kondo.is_analyzed()
        \ && s:__add_missing_by_clj_kondo_analysis(symbol)
    let added = v:true
  endif

  if ! added
        \ && iced#nrepl#is_supported_op('resolve-missing')
    call iced#nrepl#op#refactor#add_missing(symbol, {resp ->
          \ s:__add_missing_ns_resolve_missing(symbol, resp)})
    let added = v:true
  endif

  if ! added
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
        silent normal! gv"0p
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
      keepjumps silent normal! %hy
      let arity_and_body = @@
      if beginning_var_name[1] == beginning_of_arity[1]
        let @@ = printf("\n  ([])\n  (%s)", arity_and_body)
        keepjumps silent normal! gv"0pj
      else
        let @@ = printf("([])\n  (%s)", arity_and_body)
        keepjumps silent normal! gv"0p
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
  call iced#message#echom('fetching')
  return iced#promise#call('iced#nrepl#var#get', [a:symbol])
        \.then(funcref('s:got_var'))
endfunction

function! s:got_var(var) abort
  if !has_key(a:var, 'file')
        \ || !has_key(a:var, 'ns')
        \ || !has_key(a:var, 'name')
        \ || !has_key(a:var, 'column')
        \ || !has_key(a:var, 'line')
    return iced#message#error('not_found')
  endif

  let ns = a:var['ns']
  let name = a:var['name']
  let file = a:var['file']
  let column = a:var['column']
  let line = a:var['line']

  " find_symbol prints exception for a file in a jar
  if stridx(file, 'zipfile:/') == 0
    return iced#message#error('not_found')
  endif

  let kondo = iced#system#get('clj_kondo')
  if kondo.is_analyzed()
    if kondo.is_analyzing()
      let res = iced#system#get('io').input(iced#message#get('clj_kondo_analyzing'))
      " for line break
      echom ' '
      if res !=# '' && res !=# 'y' && res !=# 'Y'
        return iced#message#warning('canceled')
      endif
    endif

    let references = kondo.references(ns, name)
    let definition = kondo.var_definition(ns, name)
    if ! empty(definition)
      let references += [definition]
    endif

    if empty(references)
      return iced#message#error('not_found')
    endif

    let io = iced#system#get('io')
    let new_name = trim(io.input('New name: ', name))
    if empty(new_name)
      return iced#message#info('canceled')
    endif

    let occurrences = map(references, {_, v -> {
          \ 'file': get(v, 'filename'),
          \ 'name': printf('%s/%s', get(v, 'to', get(v, 'ns')), get(v, 'name')),
          \ 'line-beg': get(v, 'name-row'),
          \ 'line-end': get(v, 'name-end-row'),
          \ 'col-beg': get(v, 'name-col'),
          \ 'col-end': get(v, 'name-end-col'),
          \ }})
    call s:rename_occurrences(occurrences, name, new_name)
    return iced#promise#resolve(v:true)

  else
    return iced#promise#call('iced#nrepl#op#refactor#find_symbol', [ns, name, file, line, column])
          \.then(funcref('s:found_symbols', [name]))
  endif
endfunction

function! s:found_symbols(old_name, symbols) abort
  let edn = iced#system#get('edn')

  let io = iced#system#get('io')
  let new_name = trim(io.input('New name: ', a:old_name))
  if empty(new_name)
    return iced#message#info('canceled')
  endif

  let symbols = filter(a:symbols, {i, v -> has_key(v, 'occurrence')})
  let occurrences = map(symbols, {i, v -> iced#promise#sync(edn.decode, [v['occurrence']])})

  return s:rename_occurrences(occurrences, a:old_name, new_name)
endfunction

function! s:rename_occurrences(occurrences, old_name, new_name) abort
  let occurrences = copy(a:occurrences)
  " occurrence to the right should be renamed first to avoid shifting column numbers
  call sort(occurrences, {a, b -> b['col-beg'] - a['col-beg']})

  let ctx = iced#util#save_context()
  try
    call map(occurrences, {i, v -> s:rename_occurrence(a:old_name, a:new_name, v)})
  finally
    call iced#util#restore_context(ctx)
  endtry
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

  " when occurrence is definition the find-symbol reports whole form
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
