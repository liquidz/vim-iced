let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:M = s:V.import('Vim.Message')
let s:last_warnings = []

let s:enabled = v:true
let g:iced#lint#linters = get(g:, 'iced#lint#linters', [])

function! s:lint(warnings) abort
  call iced#sign#unplace_all()
  let s:last_warnings = a:warnings
  for warn in s:last_warnings
    if !has_key(warn, 'line') || !has_key(warn, 'path') | continue | endif
    call iced#sign#place('iced_lint', warn['line'], warn['path'])
  endfor
endfunction

function! iced#lint#current_file() abort
  if !iced#nrepl#is_connected() || !s:enabled
    return
  endif

  let file = expand('%:p')
  call iced#nrepl#iced#lint_file(file, g:iced#lint#linters, funcref('s:lint'))
endfunction

function! iced#lint#echo_message() abort
  if !s:enabled
    return
  endif

  let lnum = line('.')
  let path = expand('%:p')
  for warn in s:last_warnings
    if !has_key(warn, 'line') || !has_key(warn, 'path') | continue | endif
    if warn['line'] == lnum && warn['path'] ==# path
      return s:M.echo('WarningMsg', warn['msg'])
    endif
  endfor
endfunction

function! iced#lint#toggle() abort
  let s:enabled = !s:enabled

  if s:enabled
    return iced#message#info('lint_enabled')
  endif
  return iced#message#info('lint_disabled')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
