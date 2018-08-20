scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:V  = vital#iced#new()
let s:B  = s:V.import('Vim.Buffer')
let s:BM = s:V.import('Vim.BufferManager')

let s:manager = v:none
let s:info = {}

function! s:focus_window(bufwin_num) abort
  execute a:bufwin_num . 'wincmd w'
endfunction

function! s:bufnr(bufname) abort
  let info = get(s:info, a:bufname, {})
  return get(info, 'bufnr', -1)
endfunction

function! s:bufwinnr(bufname) abort
  return bufwinnr(s:bufnr(a:bufname))
endfunction

function! iced#buffer#is_initialized(bufname) abort
  return (empty(get(s:info, a:bufname, {})) ? v:false : v:true)
endfunction

function! s:buffer_manager() abort
  if s:manager == v:none
    let s:manager = s:BM.new()
  endif

  return s:manager
endfunction

function! iced#buffer#init(bufname, ...) abort
  if iced#buffer#is_initialized(a:bufname)
    return
  endif

  let manager = s:buffer_manager()
  let s:info[a:bufname] = manager.open(a:bufname)

  let InitFn = get(a:, 1, v:none)
  if iced#util#is_function(InitFn)
    call InitFn(s:bufnr(a:bufname))
  endif
  silent execute ':q'
endfunction

function! iced#buffer#is_visible(bufname) abort
  return (s:bufwinnr(a:bufname) != -1)
endfunction

function! iced#buffer#open(bufname, ...) abort
  let nr = s:bufnr(a:bufname)
  if nr < 0 | return | endif
  let opt = get(a:, 1, {})

  if iced#buffer#is_visible(a:bufname)
    call s:focus_window(s:bufwinnr(a:bufname))
  else
    let current_window = winnr()
    call s:B.open(nr, {
        \ 'opener': get(opt, 'opener', 'split'),
        \ 'mods': get(opt, 'mods', ''),
        \ })

    if get(opt, 'scroll_to_bottom', v:false)
      silent normal! G
    endif

    call s:focus_window(current_window)
  endif
endfunction

function! s:delete_color_code(s) abort
  return substitute(a:s, '\[[0-9;]*m', '', 'g')
endfunction

function! iced#buffer#append(bufname, s, ...) abort
  let nr = s:bufnr(a:bufname)
  if nr < 0 | return | endif

  let opt = get(a:, 1, {})

  for line in split(a:s, '\r\?\n')
    let line = s:delete_color_code(line)
    silent call appendbufline(nr, '$', line)
  endfor

  if get(opt, 'scroll_to_bottom', v:false) && iced#buffer#is_visible(a:bufname)
    let current_window = winnr()
    call s:focus_window(bufwinnr(nr))
    silent normal! G
    call s:focus_window(current_window)
  endif
endfunction

function! iced#buffer#clear(bufname, ...) abort
  let visibled = iced#buffer#is_visible(a:bufname)
  let current_window = winnr()

  call iced#buffer#open(a:bufname)
  silent normal! ggdG

  let InitFn = get(a:, 1, v:none)
  if iced#util#is_function(InitFn)
    call InitFn(s:bufnr(a:bufname))
  endif

  if visibled
    call s:focus_window(current_window)
  else
    silent execute ':q'
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
