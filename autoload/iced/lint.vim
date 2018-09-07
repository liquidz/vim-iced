let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:M = s:V.import('Vim.Message')
let s:last_warnings = []

let g:iced#lint#linters = get(g:, 'iced#lint#linters', [])

function! s:lint_ns(resp) abort
  if !has_key(a:resp, 'lint-warnings') | return | endif

  call iced#sign#unplace_all()
  let s:last_warnings = a:resp['lint-warnings']
  for warn in s:last_warnings
    if !has_key(warn, 'line') || !has_key(warn, 'path') | continue | endif
    call iced#sign#place('iced_lint', warn['line'], warn['path'])
  endfor
endfunction

function! iced#lint#ns(...) abort
  if !iced#nrepl#is_connected() | return | endif
  let ns_name = get(a:, 1, iced#nrepl#ns#name())
  let ns_name = (empty(ns_name) ? iced#nrepl#ns#name() : ns_name)

  if !empty(ns_name)
    call iced#nrepl#iced#lint_ns(ns_name, g:iced#lint#linters, funcref('s:lint_ns'))
  endif
endfunction

function! iced#lint#echo_message() abort
  let lnum = line('.')
  let path = expand('%:p')
  for warn in s:last_warnings
    if !has_key(warn, 'line') || !has_key(warn, 'path') | continue | endif
    if warn['line'] == lnum && warn['path'] ==# path
      return s:M.echo('WarningMsg', warn['msg'])
    endif
  endfor
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
