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
  if type(s:manager) != type({})
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

function! s:apply_option(opt) abort
  if get(a:opt, 'scroll_to_top', v:false)
    silent normal! gg
  elseif get(a:opt, 'scroll_to_bottom', v:false)
    silent normal! G
  endif
endfunction

function! iced#buffer#set_var(bufname, k, v) abort
  let nr = s:bufnr(a:bufname)
  if nr < 0 | return | endif
  silent call setbufvar(nr, a:k, a:v)
endfunction

function! iced#buffer#open(bufname, ...) abort
  let nr = s:bufnr(a:bufname)
  if nr < 0 | return | endif
  let current_window = winnr()
  let opt = get(a:, 1, {})

  if iced#buffer#is_visible(a:bufname)
    call s:focus_window(s:bufwinnr(a:bufname))
  else
    call s:B.open(nr, {
        \ 'opener': get(opt, 'opener', 'split'),
        \ 'mods': get(opt, 'mods', ''),
        \ })

    if has_key(opt, 'height')
      silent exec printf(':resize %d', opt['height'])
    endif
  endif

  call s:apply_option(opt)
  call s:focus_window(current_window)
endfunction

function! iced#buffer#append(bufname, s, ...) abort
  let nr = s:bufnr(a:bufname)
  if nr < 0 | return | endif
  let opt = get(a:, 1, {})

  for line in split(a:s, '\r\?\n')
    silent call appendbufline(nr, '$', line)
  endfor

  if get(opt, 'scroll_to_bottom', v:false) && iced#buffer#is_visible(a:bufname)
    let current_window = winnr()
    call s:focus_window(bufwinnr(nr))
    silent normal! G
    call s:focus_window(current_window)
  endif
endfunction

function! iced#buffer#set_contents(bufname, s) abort
  let nr = s:bufnr(a:bufname)

  silent call deletebufline(nr, 1, '$')
  for line in split(a:s, '\r\?\n')
    silent call appendbufline(nr, '$', line)
  endfor
  silent call deletebufline(nr, 1)
endfunction

function! iced#buffer#clear(bufname, ...) abort
  let nr = s:bufnr(a:bufname)
  silent call deletebufline(nr, 1, '$')
  let InitFn = get(a:, 1, v:none)
  if iced#util#is_function(InitFn)
    call InitFn(nr)
  endif
endfunction

function! iced#buffer#close(bufname) abort
  if !iced#buffer#is_visible(a:bufname)
    return
  endif

  let current_window = winnr()
  call s:focus_window(s:bufwinnr(a:bufname))
  silent execute ':q'
  call s:focus_window(current_window)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
