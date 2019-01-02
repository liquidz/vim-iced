let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:S = s:V.import('Data.String')
let s:L = s:V.import('Data.List')

let s:tagstack = []
let g:iced#related_ns#tail_patterns =
      \ get(g:, 'iced#related_ns#tail_patterns', ['', '-test', '-spec', '\.spec'])

let g:iced#var_references#cache_dir = get(g:, 'iced#var_references#cache_dir', '/tmp')

function! s:apply_mode_to_file(mode, file) abort
  let cmd = ':edit'
  if a:mode ==# 'v'
    let cmd = ':split'
  elseif a:mode ==# 't'
    let cmd = ':tabedit'
  endif
  call iced#di#get('ex_cmd').exe(printf('%s %s', cmd, a:file))
endfunction

" s:open_ns {{{
function! s:open_ns(mode, ns_name) abort
  let resp = iced#nrepl#op#cider#sync#ns_path(a:ns_name)
  if !has_key(resp, 'path') || empty(resp['path']) || !filereadable(resp['path'])
    return iced#message#error('not_found')
  endif

  call s:apply_mode_to_file(a:mode, resp['path'])
endfunction " }}}

" s:open_var {{{
function! s:open_var_info(mode, resp) abort
  if !has_key(a:resp, 'file') | return iced#message#error('not_found') | endif
  let path = substitute(a:resp['file'], '^file:', '', '')
  if expand('%:p') !=# path
    call s:apply_mode_to_file(a:mode, path)
  endif

  let line = a:resp['line']
  let column = a:resp['column']
  call cursor(line, column)
  normal! zz
  redraw!
endfunction

function! s:open_var(mode, var_name) abort
  let arr = split(a:var_name, '/')
  if len(arr) != 2 | return iced#message#error('invalid_format', a:var_name) | endif
  call iced#nrepl#op#cider#info(arr[0], arr[1], {resp -> s:open_var_info(a:mode, resp)})
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
  call s:open_ns('e', toggle_ns)
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
  call iced#selector({'candidates': related, 'accept': funcref('s:open_ns')})
endfunction

function! iced#nrepl#navigate#related_ns() abort
  call iced#nrepl#op#iced#project_ns_list(funcref('s:ns_list'))
endfunction " }}}

" iced#nrepl#navigate#jump_to_def {{{
function! s:jump(resp) abort
  if !has_key(a:resp, 'file') | return iced#message#error('jump_not_found') | endif
  let path = substitute(a:resp['file'], '^file:', '', '')
  let line = a:resp['line']
  let column = a:resp['column']

  if stridx(path, 'jar:') == 0
    let path = substitute(path, '^jar:file:', 'zipfile:', '')
    let path = substitute(path, '!/', '::', '')
  endif

  if expand('%:p') !=# path
    execute(printf(':edit %s', path))
  endif

  call cursor(line, column)
  normal! zz
  redraw!
endfunction

function! iced#nrepl#navigate#jump_to_def(symbol) abort
  let pos = getcurpos()
  let pos[0] = bufnr('%')
  call s:L.push(s:tagstack, pos)

  let ns_name = iced#nrepl#ns#name()
  let kw = empty(a:symbol) ? expand('<cword>') : a:symbol
  call iced#nrepl#op#cider#info(ns_name, kw, function('s:jump'))
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

function! s:set_references_to_quickfix(references) abort
  call iced#qf#set(a:references)
  call iced#di#get('ex_cmd').silent_exe(':cwindow')
endfunction

function! s:reference_cache_path(ns_name, var_name) abort
  if empty(g:iced#var_references#cache_dir)
    return ''
  else
    let sep = iced#nrepl#system#separator()
    let name = s:S.hash(printf('%s:%s/%s',
          \ iced#nrepl#system#user_dir(),
          \ a:ns_name,
          \ a:var_name))
    return g:iced#var_references#cache_dir . sep . name
  endif
endfunction

function! s:find_var_references(resp, ns_name, var_name) abort
  if !has_key(a:resp, 'var-references') || empty(a:resp['var-references'])
    return iced#message#warning('no_var_references', a:ns_name, a:var_name)
  endif

  let references = a:resp['var-references']
  call iced#message#info('var_references_found', len(references))

  let cache_path = s:reference_cache_path(a:ns_name, a:var_name)
  if !empty(cache_path)
    call iced#util#save_var(references, cache_path)
  endif

  call s:set_references_to_quickfix(references)
endfunction

function! s:find_var_references_info(info_resp, ignore_cache) abort
  if !has_key(a:info_resp, 'ns') || !has_key(a:info_resp, 'name')
    return iced#message#error('not_found')
  endif

  let ns_name = a:info_resp['ns']
  let var_name = a:info_resp['name']

  let cache_path = s:reference_cache_path(ns_name, var_name)
  if !a:ignore_cache && filereadable(cache_path)
    call iced#message#info('hit_var_reference_cache')
    let references = iced#util#read_var(cache_path)
    call s:set_references_to_quickfix(references)
  else
    call iced#message#echom('finding_var_references')
    call iced#nrepl#op#iced#find_var_references(ns_name, var_name,
          \ {resp -> s:find_var_references(resp, ns_name, var_name)})
  endif
endfunction

function! iced#nrepl#navigate#find_var_references(symbol, bang) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  if iced#nrepl#current_session_key() !=# 'clj'
    return iced#message#error('invalid_session', 'clj')
  endif

  let ignore_cache = !empty(a:bang)
  let ns_name = iced#nrepl#ns#name()
  let symbol = empty(a:symbol) ? expand('<cword>') : a:symbol
  call iced#nrepl#op#cider#info(ns_name, symbol,
        \ {resp -> s:find_var_references_info(resp, ignore_cache)})
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim:fdm=marker:fdl=0
