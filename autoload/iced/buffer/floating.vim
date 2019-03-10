let s:save_cpo = &cpo
set cpo&vim

let s:bufname = 'iced_floating'
let s:default_filetype = 'clojure'
let s:index = 0
let s:max_height = 50

let g:iced#buffer#floating#time = get(g:, 'iced#buffer#floating#time', 3000)

function! s:next_index() abort
  let t = s:index
  let s:index = (s:index > 10) ? 0 : s:index + 1
  return t * s:max_height
endfunction

function! s:ensure_array_length(arr, n) abort
  let arr = copy(a:arr)
  let l = len(arr)

  if l > a:n
    for _ in range(l - a:n) | call remove(arr, -1) | endfor
  else
    let x = a:n - l
    for _ in range(a:n - l) | call add(arr, '') | endfor
  endif

  return arr
endfunction

function! s:initialize(bufnr) abort
  call setbufvar(a:bufnr, '&buflisted', 0)
  call setbufvar(a:bufnr, '&buftype', 'nofile')
  call setbufvar(a:bufnr, '&filetype', s:default_filetype)
  call setbufvar(a:bufnr, '&swapfile', 0)
  call setbufvar(a:bufnr, '&wrap', 0)
  call setbufvar(a:bufnr, '&winhl', 'Normal:Folded')
endfunction

function! iced#buffer#floating#is_supported() abort
  return exists('*nvim_open_win')
endfunction

function! iced#buffer#floating#init() abort
  if !iced#buffer#floating#is_supported() | return | endif
  call iced#buffer#init(s:bufname, funcref('s:initialize'))
endfunction

function! iced#buffer#floating#close(window_id) abort
  if !iced#buffer#floating#is_supported() | return | endif
  if win_gotoid(a:window_id)
    silent execute ':q'
  endif
endfunction

function! iced#buffer#floating#open(texts, ...) abort
  if !iced#buffer#floating#is_supported() | return | endif
  let bufnr = iced#buffer#nr(s:bufname)
  if bufnr < 0 | return | endif
  if type(a:texts) != v:t_list || empty(a:texts)
    return
  endif

  let opts = get(a:, 1, {})
  let index = s:next_index()

  let view = winsaveview()
  let line = get(opts, 'line', view['lnum'])
  let row = get(opts, 'row', line - view['topline'] + 1)
  let col = get(opts, 'col', len(getline('.')) + 1)

  let max_width = &columns - col - 5
  let width = max(map(copy(a:texts), {_, v -> len(v)})) + 2
  let width = (width > max_width) ? max_width : width
  let height = len(a:texts)
  let height = (height > s:max_height) ? s:max_height : height

  let win_opts = {'relative': 'editor', 'row': row, 'col': col}
  call nvim_buf_set_lines(
        \ bufnr,
        \ index,
        \ index + s:max_height,
        \ 0,
        \ s:ensure_array_length(a:texts, s:max_height))
  let winid = nvim_open_win(bufnr, v:false, width, height, win_opts)
  let current_winid = win_getid()

  try
    if win_gotoid(winid)
      let v = winsaveview()
      let v['lnum'] = index + 1
      let v['topline'] = index + 1
      call winrestview(v)
    endif
  finally
    call win_gotoid(current_winid)
  endtry

  if get(opts, 'auto_close', v:true)
    let time = get(opts, 'close_time', g:iced#buffer#floating#time)
    call timer_start(time, {-> iced#buffer#floating#close(winid)})
  endif

  return winid
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
