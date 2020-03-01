let s:save_cpo = &cpo
set cpo&vim

let s:V  = vital#iced#new()
let s:B  = s:V.import('Vim.Buffer')
let s:BM = s:V.import('Vim.BufferManager')

let s:manager = ''
let s:info = {}

function! s:focus_window(bufwin_num) abort
  execute a:bufwin_num . 'wincmd w'
endfunction

function! iced#buffer#nr(bufname) abort
  let info = get(s:info, a:bufname, {})
  return get(info, 'bufnr', -1)
endfunction

function! s:bufwinnr(bufname) abort
  return bufwinnr(iced#buffer#nr(a:bufname))
endfunction

function! iced#buffer#focus(expr) abort
  if type(a:expr) == v:t_string
    call s:focus_window(s:bufwinnr(a:expr))
  else
    " a:expr should be buffer number
    call s:focus_window(bufwinnr(a:expr))
  endif
  return v:true
endfunction

function! iced#buffer#is_initialized(bufname) abort
  return (empty(get(s:info, a:bufname, {})) ? v:false : v:true)
endfunction

function! s:buffer_manager() abort
  if type(s:manager) != v:t_dict
    let s:manager = s:BM.new()
  endif

  return s:manager
endfunction

function! iced#buffer#init(bufname, ...) abort
  if iced#buffer#is_initialized(a:bufname)
    return s:info[a:bufname]
  endif

  let manager = s:buffer_manager()
  let s:info[a:bufname] = manager.open(a:bufname)

  let InitFn = get(a:, 1, '')
  if type(InitFn) == v:t_func
    call InitFn(iced#buffer#nr(a:bufname))
  endif
  silent execute ':q'
  return s:info[a:bufname]
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
  let nr = iced#buffer#nr(a:bufname)
  if nr < 0 | return | endif
  silent call setbufvar(nr, a:k, a:v)
endfunction

function! iced#buffer#open(bufname, ...) abort
  let nr = iced#buffer#nr(a:bufname)
  if nr < 0 | return | endif
  let current_window = winnr()
  let opt = get(a:, 1, {})

  try
    let &eventignore = 'WinEnter,BufEnter'
    if !iced#buffer#is_visible(a:bufname)
      call s:B.open(nr, {
            \ 'opener': get(opt, 'opener', 'split'),
            \ 'mods': get(opt, 'mods', ''),
            \ })

      if has_key(opt, 'height')
        silent exec printf(':resize %d', opt['height'])
      endif

      call s:apply_option(opt)
      call s:focus_window(current_window)
    endif
  finally
    let &eventignore = ''
  endtry
endfunction

function! s:scroll_to_bottom(nr, _) abort
  let current_window = winnr()
  let last_window = winnr('#')
  try
    let &eventignore = 'WinEnter,BufEnter'
    call s:focus_window(bufwinnr(a:nr))
    silent normal! G
  finally
    call s:focus_window(last_window)
    call s:focus_window(current_window)
    let &eventignore = ''
  endtry
endfunction

function! iced#buffer#append(bufname, s, ...) abort
  let nr = iced#buffer#nr(a:bufname)
  if nr < 0 | return | endif
  let opt = get(a:, 1, {})

  for line in split(a:s, '\r\?\n')
    silent call iced#compat#appendbufline(nr, '$', line)
  endfor

  if get(opt, 'scroll_to_bottom', v:false) && iced#buffer#is_visible(a:bufname)
    call iced#system#get('timer').start_lazily('scroll_to_bottom', 500, funcref('s:scroll_to_bottom', [nr]))
  endif
endfunction

function! iced#buffer#set_contents(bufname, s) abort
  let nr = iced#buffer#nr(a:bufname)

  silent call iced#compat#deletebufline(nr, 1, '$')

  let lines = (type(a:s) == v:t_string ? split(a:s, '\r\?\n') : a:s)
  for line in lines
    silent call iced#compat#appendbufline(nr, '$', line)
  endfor
  silent call iced#compat#deletebufline(nr, 1)
endfunction

function! iced#buffer#clear(bufname, ...) abort
  let nr = iced#buffer#nr(a:bufname)
  silent call iced#compat#deletebufline(nr, 1, '$')
  let InitFn = get(a:, 1, '')
  if type(InitFn) == v:t_func
    call InitFn(nr)
  endif
endfunction

function! iced#buffer#close(bufname) abort
  if !iced#buffer#is_visible(a:bufname)
    return
  endif

  let current_window = winnr()
  let target_window = s:bufwinnr(a:bufname)
  call s:focus_window(target_window)
  silent execute ':q'

  if target_window >= current_window
    call s:focus_window(current_window)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
