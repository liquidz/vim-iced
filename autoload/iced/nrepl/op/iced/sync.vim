let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#op#iced#sync#set_indentation_rules(rules, does_overwrite) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let does_overwrite = a:does_overwrite ? 'true' : 'false'
  return iced#nrepl#sync#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'iced-set-indentation-rules',
        \ 'sesion': iced#nrepl#current_session(),
        \ 'rules': a:rules,
        \ 'does-overwrite': does_overwrite,
        \ })
endfunction

function! iced#nrepl#op#iced#sync#format_code(code, alias_map) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  return iced#nrepl#sync#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'iced-format-code-with-indents',
        \ 'sesion': iced#nrepl#current_session(),
        \ 'code': a:code,
        \ 'alias-map': a:alias_map,
        \ })
endfunction

function! iced#nrepl#op#iced#sync#calculate_indent_level(code, line_num, alias_map) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  return iced#nrepl#sync#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'iced-calculate-indent-level',
        \ 'sesion': iced#nrepl#current_session(),
        \ 'code': a:code,
        \ 'line-number': a:line_num,
        \ 'alias-map': a:alias_map,
        \ })
endfunction

function! iced#nrepl#op#iced#sync#refactor_thread_first(code) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  return iced#nrepl#sync#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'iced-refactor-thread-first',
        \ 'sesion': iced#nrepl#current_session(),
        \ 'code': a:code,
        \ })
endfunction

function! iced#nrepl#op#iced#sync#refactor_thread_last(code) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  return iced#nrepl#sync#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'iced-refactor-thread-last',
        \ 'sesion': iced#nrepl#current_session(),
        \ 'code': a:code,
        \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
