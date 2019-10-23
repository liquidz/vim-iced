let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:S = s:V.import('Data.String')
let s:L = s:V.import('Data.List')

let s:tagstack = []
let g:iced#related_ns#tail_patterns =
      \ get(g:, 'iced#related_ns#tail_patterns', ['', '-test', '-spec', '\.spec'])

let g:iced#var_references#cache_dir = get(g:, 'iced#var_references#cache_dir', '/tmp')

function! s:add_curpos_to_tagstack() abort
  let pos = getcurpos()
  let pos[0] = bufnr('%')
  call s:L.push(s:tagstack, pos)
endfunction

function! s:apply_mode_to_file(mode, file) abort
  let cmd = ':edit'
  if a:mode ==# 'v'
    let cmd = ':split'
  elseif a:mode ==# 't'
    let cmd = ':tabedit'
  endif
  call iced#system#get('ex_cmd').exe(printf('%s %s', cmd, a:file))
endfunction

" iced#nrepl#navigate#open_ns {{{
function! iced#nrepl#navigate#open_ns(mode, ns_name) abort
  let resp = iced#promise#sync('iced#nrepl#op#iced#pseudo_ns_path', [a:ns_name])
  if !has_key(resp, 'path') || empty(resp['path'])
    return iced#message#error('not_found')
  endif

  let path = resp['path']
  if !filereadable(path)
    let prompt = printf('%s: ', iced#message#get('confirm_opening_file'))
    let path = iced#system#get('io').input(prompt, path)
  endif

  if !empty(path)
    call s:apply_mode_to_file(a:mode, path)
  endif
endfunction " }}}

" s:open_var {{{
function! s:open_var_info(mode, resp) abort
  if !has_key(a:resp, 'file') | return iced#message#error('not_found') | endif
  let path = iced#util#normalize_path(a:resp['file'])

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

  call s:add_curpos_to_tagstack()
  call iced#nrepl#ns#require(ns, {_ ->
       \ iced#nrepl#op#cider#info(ns, symbol, {resp -> s:open_var_info(a:mode, resp)})})
endfunction " }}}

" iced#nrepl#navigate#cycle_ns {{{
function! iced#nrepl#navigate#cycle_ns(ns) abort
  return (s:S.ends_with(a:ns, '-test')
      \ ? substitute(a:ns, '-test$', '', '')
      \ : a:ns . '-test')
endfunction " }}}

" iced#nrepl#navigate#toggle_src_and_test {{{
function! iced#nrepl#navigate#toggle_src_and_test() abort
  if !iced#nrepl#is_connected()
    return iced#message#error('not_connected')
  endif

  let ns = iced#nrepl#ns#name()
  let toggle_ns = iced#nrepl#navigate#cycle_ns(ns)
  call iced#nrepl#navigate#open_ns('e', toggle_ns)
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
  call iced#nrepl#op#iced#project_ns_list(funcref('s:ns_list'))
endfunction " }}}

" iced#nrepl#navigate#jump_to_def {{{
function! s:jump(resp) abort
  if !has_key(a:resp, 'file') | return iced#message#error('jump_not_found') | endif
  let path = iced#util#normalize_path(a:resp['file'])
  let line = a:resp['line']
  let column = get(a:resp, 'column', '0')

  if expand('%:p') !=# path
    call iced#system#get('ex_cmd').exe(printf(':edit %s', path))
  endif

  call cursor(line, column)
  normal! zz
  redraw!
endfunction

function! iced#nrepl#navigate#jump_to_def(symbol) abort
  call s:add_curpos_to_tagstack()
  call iced#nrepl#var#get(a:symbol, funcref('s:jump'))
endfunction " }}}

" iced#nrepl#navigate#jump_back {{{
function! iced#nrepl#navigate#jump_back() abort
  if empty(s:tagstack)
    echo 'Local tag stack is empty'
  else
    let last_position = s:L.pop(s:tagstack)
    execute printf(':buffer %d', last_position[0])
    call cursor(last_position[1], last_position[2])
    normal! zz
    redraw!
  endif
endfunction " }}}

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
  call iced#nrepl#test#fetch_test_vars_by_function_under_cursor(ns_name, funcref('s:test_vars'))
endfunction " }}}

function! s:set_xref_resp_to_quickfix(key, resp) abort
  if !has_key(a:resp, a:key)
    return iced#message#error('not_found')
  endif

  let xrefs = copy(a:resp[a:key])
  call filter(xrefs, {_, v -> filereadable(v['file'])})
  call map(xrefs, {_, v -> {
        \ 'filename': v['file'],
        \ 'text': printf('%s: %s', v['name'], v['doc']),
        \ 'lnum': v['line'],
        \ }})
  if empty(xrefs) | return iced#message#info('not_found') | endif

  call iced#system#get('quickfix').setlist(xrefs, 'r')
  call iced#system#get('ex_cmd').silent_exe(':cwindow')
endfunction

let s:fn_refs_callback = function('s:set_xref_resp_to_quickfix', ['fn-refs'])
let s:fn_deps_callback = function('s:set_xref_resp_to_quickfix', ['fn-deps'])

function! s:got_var_info(resp, callback) abort
  if !has_key(a:resp, 'ns') || !has_key(a:resp, 'name')
    return iced#message#error('not_found')
  endif
  call a:callback(a:resp['ns'], a:resp['name'])
endfunction

function! iced#nrepl#navigate#browse_references() abort
  call iced#nrepl#var#extract_by_current_top_list({res ->
        \ iced#nrepl#op#cider#fn_refs(res.ns, res.var, s:fn_refs_callback)
        \ })
endfunction

function! iced#nrepl#navigate#browse_dependencies() abort
  call iced#nrepl#var#extract_by_current_top_list({res ->
        \ iced#nrepl#op#cider#fn_deps(res.ns, res.var, s:fn_deps_callback)
        \ })
endfunction

function! iced#nrepl#navigate#browse_var_references(symbol) abort
  call iced#nrepl#ns#in({_ -> iced#nrepl#var#get(a:symbol, {resp ->
        \ s:got_var_info(resp, {ns, symbol ->
        \     iced#nrepl#op#cider#fn_refs(ns, symbol, s:fn_refs_callback)
        \ })})})
endfunction

function! iced#nrepl#navigate#browse_var_dependencies(symbol) abort
  call iced#nrepl#ns#in({_ -> iced#nrepl#var#get(a:symbol, {resp ->
        \ s:got_var_info(resp, {ns, symbol ->
        \     iced#nrepl#op#cider#fn_deps(ns, symbol, s:fn_deps_callback)
        \ })})})
endfunction

function! iced#nrepl#navigate#ns_complete(arg_lead, cmd_line, cursor_pos) abort
  if !iced#nrepl#is_connected() | return [] | endif
  let resp = iced#promise#sync('iced#nrepl#op#iced#project_ns_list', [])
  return join(get(resp, 'project-ns-list', []), "\n")
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim:fdm=marker:fdl=0
