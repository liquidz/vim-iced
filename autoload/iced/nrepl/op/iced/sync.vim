let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#op#iced#sync#set_indentation_rules(rules, does_overwrite) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let msg = {
        \ 'id': iced#nrepl#id(),
        \ 'op': 'iced-set-indentation-rules',
        \ 'session': iced#nrepl#current_session(),
        \ 'rules': a:rules,
        \ }

  if a:does_overwrite
    let msg['overwrite?'] = 1
  endif

  return iced#nrepl#sync#send(msg)
endfunction

function! iced#nrepl#op#iced#sync#format_code(code, alias_map) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  return iced#nrepl#sync#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'iced-format-code-with-indents',
        \ 'session': iced#nrepl#current_session(),
        \ 'code': a:code,
        \ 'alias-map': a:alias_map,
        \ })
endfunction

function! iced#nrepl#op#iced#sync#calculate_indent_level(code, line_num, alias_map) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  return iced#nrepl#sync#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'iced-calculate-indent-level',
        \ 'session': iced#nrepl#current_session(),
        \ 'code': a:code,
        \ 'line-number': a:line_num,
        \ 'alias-map': a:alias_map,
        \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
