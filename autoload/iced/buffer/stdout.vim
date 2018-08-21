scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

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

function! s:initialize(bufnr) abort
  call setbufvar(a:bufnr, '&buflisted', 0)
  call setbufvar(a:bufnr, '&buftype', 'nofile')
  call setbufvar(a:bufnr, '&filetype', 'clojure')
  call setbufvar(a:bufnr, '&swapfile', 0)

  for line in split(g:iced#buffer#stdout#init_text, '\r\?\n')
    silent call appendbufline(a:bufnr, '$', line)
  endfor
  silent call deletebufline(a:bufnr, 1)
endfunction

function! s:delete_color_code(s) abort
  return substitute(a:s, '\[[0-9;]*m', '', 'g')
endfunction

function! iced#buffer#stdout#init() abort
  call iced#buffer#init(s:bufname, funcref('s:initialize'))
endfunction

function! iced#buffer#stdout#open() abort
  call iced#buffer#open(
      \ s:bufname,
      \ {'mods': g:iced#buffer#stdout#mods,
      \  'scroll_to_bottom': v:true})
endfunction

function! iced#buffer#stdout#append(s) abort
  call iced#buffer#append(
      \ s:bufname,
      \ s:delete_color_code(a:s),
      \ {'scroll_to_bottom': v:true})
endfunction

function! iced#buffer#stdout#clear() abort
  call iced#buffer#clear(s:bufname, funcref('s:initialize'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
