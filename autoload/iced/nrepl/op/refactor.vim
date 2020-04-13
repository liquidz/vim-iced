let s:save_cpo = &cpo
set cpo&vim

let g:iced#refactor#prefix_rewriting = get(g:, 'iced#refactor#prefix_rewriting', v:false)

let s:cache = iced#cache#factory(expand('<sfile>'))

function! iced#nrepl#op#refactor#__clear_cache() abort
  call s:cache.clear()
endfunction

function! iced#nrepl#op#refactor#clean_ns(callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let path = expand('%:p')
  let prefix_rewriting = (g:iced#refactor#prefix_rewriting ? 'true' : 'false')
  call iced#nrepl#send({
      \ 'op': 'clean-ns',
      \ 'path': path,
      \ 'prefix-rewriting': prefix_rewriting,
      \ 'session': iced#nrepl#current_session(),
      \ 'callback': a:callback,
      \ })
endfunction

function! iced#nrepl#op#refactor#add_missing(symbol, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let symbol = empty(a:symbol) ? iced#nrepl#var#cword() : a:symbol
  call iced#message#echom('resolving_missing')
  call iced#nrepl#send({
        \ 'op': 'resolve-missing',
        \ 'symbol': symbol,
        \ 'session': iced#nrepl#current_session(),
        \ 'callback': a:callback,
        \ })
endfunction

function! iced#nrepl#op#refactor#find_used_locals(filepath, line, column, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  call iced#nrepl#send({
        \ 'op': 'find-used-locals',
        \ 'id': iced#nrepl#id(),
        \ 'session': iced#nrepl#current_session(),
        \ 'file': a:filepath,
        \ 'line': a:line,
        \ 'column': a:column,
        \ 'callback': a:callback,
        \ })
endfunction

function! iced#nrepl#op#refactor#extract_definition(filepath, ns_name, symbol, line, column, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  call iced#nrepl#send({
        \ 'op': 'extract-definition',
        \ 'id': iced#nrepl#id(),
        \ 'session': iced#nrepl#current_session(),
        \ 'file': a:filepath,
        \ 'ns': a:ns_name,
        \ 'name': a:symbol,
        \ 'line': a:line,
        \ 'column': a:column,
        \ 'callback': a:callback,
        \ })
endfunction

function! s:parse_aliases_value(v) abort
  let result = {}
  if empty(a:v) | return result | endif
  let v = trim(a:v)
  for pair in split(trim(a:v), ',')
    let [alias, name] = split(pair, '(')
    let result[trim(alias)] = split(substitute(name, '[()]', '', 'g'), ' \+')
  endfor
  return result
endfunction

function! s:ensure_tuple(ls) abort
  let l = len(a:ls)
  if l == 2
    return a:ls
  elseif l > 0
    return [a:ls[0], '']
  endif
  return ['', '']
endfunction

function! s:__all_ns_aliases(resp) abort
  let result = {}
  let aliases = a:resp['namespace-aliases']
  let aliases = strpart(aliases, 1, len(aliases)-3)
  for grp in split(aliases, '}')
    let [k, v] = s:ensure_tuple(split(grp, '{'))
    let k = strpart(trim(k), 1)
    let result[k] = s:parse_aliases_value(v)
  endfor

  if !empty(result)
    call s:cache.set('iced#nrepl#op#refactor#all_ns_aliases', result)
  endif

  return result
endfunction

function! iced#nrepl#op#refactor#all_ns_aliases(callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let cached = s:cache.get('iced#nrepl#op#refactor#all_ns_aliases')
  if !empty(cached)
    return a:callback(cached)
  endif

  call iced#nrepl#send({
        \ 'op': 'namespace-aliases',
        \ 'id': iced#nrepl#id(),
        \ 'session': iced#nrepl#current_session(),
        \ 'callback': {resp -> a:callback(s:__all_ns_aliases(resp))},
        \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
