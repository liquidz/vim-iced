scriptencoding utf-8
let s:save_cpo = &cpoptions
set cpoptions&vim

let s:bufname = 'iced_stdout'
let s:default_init_text = join([
    \ ';;',
    \ ';; Iced Buffer',
    \ ';;',
    \ '',
    \ ], "\n")

let g:iced#buffer#stdout#init_text = get(g:, 'iced#buffer#stdout#init_text', s:default_init_text)
let g:iced#buffer#stdout#mods = get(g:, 'iced#buffer#stdout#mods', '')
let g:iced#buffer#stdout#max_line = get(g:, 'iced#buffer#stdout#max_line', 512)
let g:iced#buffer#stdout#file = get(g:, 'iced#buffer#stdout#file', '')

function! s:initialize(bufnr) abort
  call setbufvar(a:bufnr, '&buflisted', 0)
  call setbufvar(a:bufnr, '&buftype', 'nofile')
  call setbufvar(a:bufnr, '&filetype', 'clojure')
  call setbufvar(a:bufnr, '&swapfile', 0)

  for line in split(g:iced#buffer#stdout#init_text, '\r\?\n')
    silent call iced#compat#appendbufline(a:bufnr, '$', line)
  endfor
  silent call iced#compat#deletebufline(a:bufnr, 1)

  if !empty(g:iced#buffer#stdout#file)
    call writefile(getbufline(a:bufnr, 1, '$'), g:iced#buffer#stdout#file)
  endif
endfunction

function! iced#buffer#stdout#init() abort
  return iced#buffer#init(s:bufname, funcref('s:initialize'))
endfunction

function! iced#buffer#stdout#open() abort
  call iced#buffer#open(
      \ s:bufname,
      \ {'mods': g:iced#buffer#stdout#mods,
      \  'scroll_to_bottom': v:true})
endfunction

function! iced#buffer#stdout#append(s) abort
  let s = iced#util#delete_color_code(a:s)
  if !empty(g:iced#buffer#stdout#file)
    call writefile(split(s, '\r\?\n'), g:iced#buffer#stdout#file, 'a')
  endif

  call iced#buffer#append(
      \ s:bufname,
      \ s,
      \ {'scroll_to_bottom': v:true})
endfunction

function! iced#buffer#stdout#clear() abort
  call iced#buffer#clear(s:bufname, funcref('s:initialize'))
endfunction

function! iced#buffer#stdout#close() abort
  call iced#buffer#close(s:bufname)
endfunction

function! iced#buffer#stdout#is_visible() abort
  return iced#buffer#is_visible(s:bufname)
endfunction

function! iced#buffer#stdout#focus() abort
  call iced#buffer#focus(s:bufname)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
