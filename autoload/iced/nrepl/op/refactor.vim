let s:save_cpo = &cpo
set cpo&vim

let g:iced#refactor#prefix_rewriting = get(g:, 'iced#refactor#prefix_rewriting', v:false)

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

let &cpo = s:save_cpo
unlet s:save_cpo
