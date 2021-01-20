let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:S = s:V.import('Data.String')
let s:L = s:V.import('Data.List')

let g:iced#related_ns#tail_patterns =
      \ get(g:, 'iced#related_ns#tail_patterns', ['', '-test', '-spec', '\.spec'])

let g:iced#var_references#cache_dir = get(g:, 'iced#var_references#cache_dir', '/tmp')

" definitions to jump to qualified keyword
let g:iced#qualified_key_def_prefixes = get(g:, 'iced#qualified_key_def_prefixes', [])
let s:default_qualified_key_def_prefixes = [
      \ '^',
      \ 'reg-cofx',
      \ 'reg-event-ctx',
      \ 'reg-event-db',
      \ 'reg-event-fx',
      \ 'reg-fx',
      \ 'reg-sub',
      \ 'reg-sub-raw',
      \ ]
let s:qualified_key_def_prefix_regex = printf('\(%s\)',
      \ join(map(s:default_qualified_key_def_prefixes + g:iced#qualified_key_def_prefixes,
      \          {_, v -> printf('%s\s\+', v)}),
      \      '\|'))

function! s:apply_mode_to_file(mode, file) abort
  let cmd = ':edit'
  if a:mode ==# 'v'
    let cmd = ':split'
  elseif a:mode ==# 't'
    let cmd = ':tabedit'
  endif
  call iced#system#get('tagstack').add_here()
  call iced#system#get('ex_cmd').exe(printf('%s %s', cmd, a:file))
endfunction

" iced#nrepl#navigate#open_ns {{{
function! s:__open_ns(mode, resp) abort
  if !has_key(a:resp, 'path') || empty(a:resp['path'])
    return iced#message#error('not_found')
  endif

  let path = a:resp['path']
  if !filereadable(path)
    let prompt = printf('%s: ', iced#message#get('confirm_opening_file'))
    let path = iced#system#get('io').input(prompt, path)
  endif

  if !empty(path)
    call s:apply_mode_to_file(a:mode, path)
  endif
endfunction

function! iced#nrepl#navigate#open_ns(mode, ns_name) abort
  call iced#message#echom('fetching_pseudo_ns_path')
  " NOTE: Use `future` because candidate is not displayed correctly in `input` for Vim
  return iced#nrepl#op#iced#pseudo_ns_path(a:ns_name, {resp ->
        \ iced#system#get('future').do({-> s:__open_ns(a:mode, resp)})
        \ })
endfunction " }}}

" s:open_var {{{
function! s:open_var_info(mode, resp) abort
  if !has_key(a:resp, 'file') | return iced#message#error('not_found') | endif
  let path = a:resp['file']

  if expand('%:p') !=# path
    call s:apply_mode_to_file(a:mode, path)
  endif

  let line = a:resp['line']
  let column = a:resp['column']
  call cursor(line, column)
  normal! zz
  redraw!
endfunction

function! s:open_var(mode, candidate) abort
  let var_name = split(a:candidate, '\t')[0]
  let arr = split(var_name, '/')
  if len(arr) != 2 | return iced#message#error('invalid_format', var_name) | endif

  let ns = arr[0]
  let symbol = arr[1]

  call iced#system#get('tagstack').add_here()
  call iced#nrepl#ns#require(ns, {_ ->
       \ iced#nrepl#op#cider#info(ns, symbol, {resp -> s:open_var_info(a:mode, resp)})})
endfunction " }}}

" iced#nrepl#navigate#cycle_ns {{{
function! iced#nrepl#navigate#cycle_ns(ns) abort
  return (s:S.ends_with(a:ns, '-test')
      \ ? substitute(a:ns, '-test$', '', '')
      \ : a:ns . '-test')
endfunction " }}}

" iced#nrepl#navigate#cycle_src_and_test {{{
function! iced#nrepl#navigate#cycle_src_and_test() abort
  if !iced#nrepl#is_connected()
    return iced#message#error('not_connected')
  endif

  let ns = iced#nrepl#ns#name()
  let cycle_ns = iced#nrepl#navigate#cycle_ns(ns)
  call iced#nrepl#navigate#open_ns('e', cycle_ns)
endfunction " }}}

" iced#nrepl#navigate#related_ns {{{
function! s:ns_list(resp) abort
  if !has_key(a:resp, 'project-ns-list') | return iced#message#error('ns_list_error') | endif

  let ns = iced#nrepl#ns#name()
  let arr = split(ns, '\.')
  let ns_head = arr[0]
  let ns_tail = substitute(arr[len(arr)-1], '-test$', '', '')
  let pattern = printf('^%s\.\(.\+\.\)\?\(%s\)$',
        \ ns_head,
        \ join(map(copy(g:iced#related_ns#tail_patterns),
        \          {_, v -> printf('%s%s', ns_tail, v)}), '\|'))

  let related = filter(copy(a:resp['project-ns-list']), {_, v -> (v !=# ns && match(v, pattern) != -1)})
  if empty(related) | return iced#message#error('not_found') | endif
  call iced#selector({'candidates': related, 'accept': function('iced#nrepl#navigate#open_ns')})
endfunction

function! iced#nrepl#navigate#related_ns() abort
  call iced#message#info('fetching')
  call iced#nrepl#op#iced#project_ns_list(funcref('s:ns_list'))
endfunction " }}}

" iced#nrepl#navigate#jump_to_def {{{
function! iced#nrepl#navigate#jump_to_def(symbol) abort
  call iced#system#get('tagstack').add_here()

  let symbol = empty(a:symbol)
        \ ? iced#nrepl#var#cword()
        \ : a:symbol

  let kondo = iced#system#get('clj_kondo')
  if stridx(symbol, '::') == 0
    return s:jump_to_qualified_keyword(symbol)
  elseif kondo.is_analyzed() && g:iced_enable_clj_kondo_local_analysis
    let local_def = kondo.local_definition(expand('%:p'), line('.'), symbol)
    if ! empty(local_def)
      return s:jump_to_local_definition(local_def)
    else
      return iced#nrepl#var#get(symbol, funcref('s:jump', [symbol]))
    endif
  else
    return iced#nrepl#var#get(symbol, funcref('s:jump', [symbol]))
  endif
endfunction

function! s:jump_to_qualified_keyword(keyword) abort
  let current_ns_name = iced#nrepl#ns#name()
  let ns_name = ''
  let kw_name = ''

  let slash_idx = stridx(a:keyword, '/')
  if slash_idx == -1
    let ns_name = current_ns_name
    let kw_name = strpart(a:keyword, 2)
  else
    let alias_dict = iced#nrepl#ns#alias_dict(current_ns_name)
    let ns_name = strpart(a:keyword, 2, slash_idx - 2)
    let ns_name = get(alias_dict, ns_name, ns_name)
    let kw_name = strpart(a:keyword, slash_idx + 1)
  endif

  let path = ''
  if ns_name ==# current_ns_name
    let path = expand('%:p')
  else
    let kondo = iced#system#get('clj_kondo')
    if kondo.is_analyzed()
      let path = kondo.ns_path(ns_name)
    else
      let res = iced#promise#sync('iced#nrepl#op#cider#ns_path', [ns_name])
      let path = get(res, 'path', '')
    endif

    if empty(path)
      return iced#message#error('jump_not_found')
    endif
  endif

  " Open path
  if expand('%:p') !=# path
    call iced#system#get('ex_cmd').exe(printf(':edit %s', path))
  endif

  " Search qualified keyword by s:qualified_key_def_prefix_regex
  let pattern = printf('%s::%s', s:qualified_key_def_prefix_regex, kw_name)
  let curpos = getcurpos()
  call cursor(1, 1)

  let pos = searchpos(pattern, 'n')
  if pos == [0, 0]
    " When not found, search the first qualified keyword that appear
    let pos = searchpos(printf('::%s', kw_name), 'n')
    if pos == [0, 0]
      return setpos('.', curpos)
    endif
  endif

  call cursor(pos[0], pos[1])
  normal! zz
endfunction

function!  s:jump_to_local_definition(local_def) abort
  let row = get(a:local_def, 'row', 1)
  let col = get(a:local_def, 'col', 1)

  call cursor(row, col)
endfunction

function! s:jump(base_symbol, resp) abort
  let path = ''
  let line = 0
  let column = 0

  if iced#util#has_status(a:resp, 'no-info')
    return iced#message#error('jump_not_found')
  endif

  if !has_key(a:resp, 'file')
    let kondo = iced#system#get('clj_kondo')
    let d = kondo.is_analyzed()
          \ ? kondo.var_definition(get(a:resp, 'ns'), get(a:resp, 'name'))
          \ : v:false
    if type(d) == v:t_dict
      let path = d['filename']
      let line = d['row']
      let column = d['col']
    else
      return iced#message#error('jump_not_found')
    endif
  else
    let path = a:resp['file']
    let line = a:resp['line']
    let column = get(a:resp, 'column', '0')
  endif

  if expand('%:p') !=# path
    call iced#system#get('ex_cmd').exe(printf(':edit %s', path))
  endif

  call cursor(line, column)
  normal! zz
  redraw!
endfunction
" }}}

" iced#nrepl#navigate#test {{{
function! s:test_vars(var_name, test_vars) abort
  if empty(a:test_vars)
    return iced#message#warning('no_test_vars_for', a:var_name)
  endif

  call iced#selector({'candidates': a:test_vars, 'accept': funcref('s:open_var')})
endfunction

function! iced#nrepl#navigate#test() abort
  let ns_name = iced#nrepl#ns#name()
  if s:S.ends_with(ns_name, '-test') | return iced#message#warning('already_in_test_ns') | endif

  let ns_name = iced#nrepl#navigate#cycle_ns(ns_name)
  return iced#nrepl#test#fetch_test_vars_by_function_under_cursor(ns_name, funcref('s:test_vars'))
endfunction " }}}

function! s:set_xref_resp_to_quickfix(key, resp) abort
  if !has_key(a:resp, a:key)
    return iced#message#error('not_found')
  endif

  let xrefs = copy(a:resp[a:key])
  call filter(xrefs, {_, v -> filereadable(v['file'])})
  call map(xrefs, {_, v -> {
        \ 'filename': v['file'],
        \ 'text': (has_key(v, 'doc') ? printf('%s: %s', v['name'], v['doc']) : v['name']),
        \ 'lnum': v['line'],
        \ }})
  if empty(xrefs) | return iced#message#info('not_found') | endif

  call iced#system#get('quickfix').setloclist(win_getid(), xrefs)
  call iced#system#get('ex_cmd').silent_exe(':lwindow')
endfunction

let s:fn_refs_callback = function('s:set_xref_resp_to_quickfix', ['fn-refs'])
let s:fn_deps_callback = function('s:set_xref_resp_to_quickfix', ['fn-deps'])

function! s:got_var_info(resp, callback) abort
  if !has_key(a:resp, 'ns') || !has_key(a:resp, 'name')
    return iced#message#error('not_found')
  endif
  call a:callback(a:resp['ns'], a:resp['name'])
endfunction

function! s:get_name_from_clj_kondo_analysis(v) abort
  let ns_name = get(a:v, 'from', '')
  let var_name = get(a:v, 'from-var', '')

  if empty(ns_name) && empty(var_name)
    return ''
  elseif empty(ns_name)
    return var_name
  elseif empty(var_name)
    return ns_name
  else
    return printf('%s/%s', ns_name, var_name)
  endif
endfunction

function! s:clj_kondo_analysis_to_fn_refs(analysis) abort
  return {'fn-refs': map(a:analysis, {_, v ->
       \ {'file': get(v, 'filename', ''),
       \  'name': s:get_name_from_clj_kondo_analysis(v),
       \  'line': get(v, 'row', 1),
       \  }})}
endfunction

function! s:clj_kondo_analysis_to_fn_deps(analysis) abort
  return {'fn-deps': map(a:analysis, {_, v ->
        \ {'file': get(v, 'filename', ''),
        \  'name': (has_key(v, 'ns') ? printf('%s/%s', get(v, 'ns', ''), get(v, 'name', ''))
        \                            : get(v, 'name', '')),
        \  'line': get(v, 'row', 1),
        \  }})}
endfunction

function! iced#nrepl#navigate#browse_references() abort
  if !iced#nrepl#is_connected()
    return iced#message#error('not_connected')
  endif

  let kondo = iced#system#get('clj_kondo')
  if kondo.is_analyzed()
    " Use clj-kondo's analysis
    call iced#nrepl#ns#in({_ -> iced#nrepl#var#extract_by_current_top_list({res ->
          \ s:fn_refs_callback(s:clj_kondo_analysis_to_fn_refs(kondo.references(res.ns, res.name)))
          \ })})
  elseif iced#nrepl#is_supported_op('fn-refs')
    " Use cider-nrepl's xref op
    " In this case, only loaded vars are detected.
    call iced#nrepl#ns#in({_ -> iced#nrepl#var#extract_by_current_top_list({res ->
          \ iced#nrepl#op#cider#fn_refs(res.ns, res.name, s:fn_refs_callback)
          \ })})
  else
    call iced#message#error('not_supported')
  endif
endfunction

function! iced#nrepl#navigate#browse_dependencies() abort
  if !iced#nrepl#is_connected()
    return iced#message#error('not_connected')
  endif

  let kondo = iced#system#get('clj_kondo')
  if kondo.is_analyzed()
    " Use clj-kondo's analysis
    call iced#nrepl#ns#in({_ -> iced#nrepl#var#extract_by_current_top_list({res ->
          \ s:fn_deps_callback(s:clj_kondo_analysis_to_fn_deps(kondo.dependencies(res.ns, res.name)))
          \ })})
  elseif iced#nrepl#is_supported_op('fn-deps')
    " Use cider-nrepl's xref op
    " In this case, only loaded vars are detected.
    call iced#nrepl#ns#in({_ -> iced#nrepl#var#extract_by_current_top_list({res ->
          \ iced#nrepl#op#cider#fn_deps(res.ns, res.name, s:fn_deps_callback)
          \ })})
  else
    call iced#message#error('not_supported')
  endif
endfunction

function! iced#nrepl#navigate#browse_var_references(symbol) abort
  if !iced#nrepl#is_connected()
    return iced#message#error('not_connected')
  endif

  let kondo = iced#system#get('clj_kondo')
  if kondo.is_analyzed()
    " Use clj-kondo's analysis
    call iced#nrepl#ns#in({_ -> iced#nrepl#var#get(a:symbol, {resp ->
          \ s:got_var_info(resp, {ns, symbol ->
          \     s:fn_refs_callback(s:clj_kondo_analysis_to_fn_refs(kondo.references(ns, symbol)))
          \ })})})
  elseif iced#nrepl#is_supported_op('fn-refs')
    " Use cider-nrepl's xref op
    " In this case, only loaded vars are detected.
    call iced#nrepl#ns#in({_ -> iced#nrepl#var#get(a:symbol, {resp ->
          \ s:got_var_info(resp, {ns, symbol ->
          \     iced#nrepl#op#cider#fn_refs(ns, symbol, s:fn_refs_callback)
          \ })})})
  else
    call iced#message#error('not_supported')
  endif
endfunction

function! iced#nrepl#navigate#browse_var_dependencies(symbol) abort
  if !iced#nrepl#is_connected()
    return iced#message#error('not_connected')
  endif

  let kondo = iced#system#get('clj_kondo')
  if kondo.is_analyzed()
    " Use clj-kondo's analysis
    call iced#nrepl#ns#in({_ -> iced#nrepl#var#get(a:symbol, {resp ->
          \ s:got_var_info(resp, {ns, symbol ->
          \     s:fn_deps_callback(s:clj_kondo_analysis_to_fn_deps(kondo.dependencies(ns, symbol)))
          \ })})})
  elseif iced#nrepl#is_supported_op('fn-deps')
    " Use cider-nrepl's xref op
    " In this case, only loaded vars are detected.
    call iced#nrepl#ns#in({_ -> iced#nrepl#var#get(a:symbol, {resp ->
          \ s:got_var_info(resp, {ns, symbol ->
          \     iced#nrepl#op#cider#fn_deps(ns, symbol, s:fn_deps_callback)
          \ })})})
  else
    call iced#message#error('not_supported')
  endif
endfunction

function! iced#nrepl#navigate#ns_complete(arg_lead, cmd_line, cursor_pos) abort
  if !iced#nrepl#is_connected() | return [] | endif
  let resp = iced#promise#sync('iced#nrepl#op#iced#project_ns_list', [])
  return join(get(resp, 'project-ns-list', []), "\n")
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
