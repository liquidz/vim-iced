let s:save_cpo = &cpo
set cpo&vim

let s:bufname = 'iced_error'

let g:iced#buffer#error#height = get(g:, 'iced#buffer#error#height', &previewheight)

function! s:initialize(bufnr) abort
  call setbufvar(a:bufnr, '&buflisted', 0)
  call setbufvar(a:bufnr, '&buftype', 'nofile')
  call setbufvar(a:bufnr, '&filetype', 'clojure')
  call setbufvar(a:bufnr, '&swapfile', 0)
endfunction

function! iced#buffer#error#init() abort
  call iced#buffer#init(s:bufname, funcref('s:initialize'))
endfunction

function! iced#buffer#error#open(text) abort
  if empty(a:text)
    call iced#buffer#close(s:bufname)
    return
  endif

  call iced#buffer#set_contents(s:bufname, a:text)
  call iced#buffer#open(
      \ s:bufname,
      \ {'opener': 'split',
      \  'mods': 'belowright',
      \  'scroll_to_top': v:true,
      \  'height': g:iced#buffer#error#height})
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
