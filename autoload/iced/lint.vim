let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:M = s:V.import('Vim.Message')
let s:last_warnings = []

let s:enabled = v:true
let s:sign_name = 'iced_lint'
let g:iced#eastwood#option = get(g:, 'iced#eastwood#option', {})

function! iced#lint#is_enabled() abort
  return s:enabled
endfunction

function! s:lint(warnings) abort
  let s:last_warnings = a:warnings
  for warn in s:last_warnings
    if !has_key(warn, 'line') || !has_key(warn, 'path') | continue | endif
    call iced#sign#place(s:sign_name, warn['line'], warn['path'])
  endfor
endfunction

function! iced#lint#current_file() abort
  if !iced#nrepl#is_connected() || !s:enabled || iced#nrepl#op#iced#is_lint_running()
    return
  endif

  let s:last_warnings = []
  call iced#sign#unplace_by_name(s:sign_name)
  let file = expand('%:p')

  call iced#nrepl#op#iced#lint_file(file, g:iced#eastwood#option, funcref('s:lint'))
endfunction

function! iced#lint#find_message(lnum, path) abort
  for warn in s:last_warnings
    if !has_key(warn, 'line') || !has_key(warn, 'path') | continue | endif
    if warn['line'] == a:lnum && warn['path'] ==# a:path
      return warn['msg']
    endif
  endfor
  return ''
endfunction

function! iced#lint#echo_message() abort
  if !s:enabled | return | endif

  let msg = iced#lint#find_message(line('.'), expand('%:p'))
  if !empty(msg)
    call s:M.echo('WarningMsg', iced#util#shorten(msg))
  endif
endfunction

function! iced#lint#toggle() abort
  let s:enabled = !s:enabled

  if s:enabled
    return iced#message#info('lint_enabled')
  endif
  call iced#message#info('lint_disabled')
  call iced#sign#unplace_all()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
