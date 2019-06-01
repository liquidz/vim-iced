let s:save_cpo = &cpoptions
set cpoptions&vim

let s:bufname = 'iced_floating'
let s:default_filetype = 'clojure'

let s:popup = {
      \ 'env': 'neovim',
      \ 'index': 0,
      \ }

function! s:init_win(winid) abort
  call setwinvar(a:winid, '&signcolumn', 'no')
endfunction

function! s:is_supported() abort
  return exists('*nvim_open_win')
endfunction

function! s:initialize(bufnr) abort
  call setbufvar(a:bufnr, '&buflisted', 0)
  call setbufvar(a:bufnr, '&buftype', 'nofile')
  call setbufvar(a:bufnr, '&filetype', s:default_filetype)
  call setbufvar(a:bufnr, '&swapfile', 0)
  call setbufvar(a:bufnr, '&wrap', 0)
  call setbufvar(a:bufnr, '&winhl', 'Normal:Folded')
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

function! s:popup.is_supported() abort
  return s:is_supported()
endfunction

function! s:popup.next_index() abort
  let t = self.index
  let self['index'] = (t > 10) ? 0 : t + 1

endfunction

function! s:popup.open(texts, ...) abort
  if !s:is_supported() | return | endif

  let bufnr = iced#buffer#nr(s:bufname)
  if bufnr < 0 | return | endif
  if type(a:texts) != v:t_list || empty(a:texts)
    return
  endif

  " TODO: support 'highlight' option
  let opts = get(a:, 1, {})
  let index = self.next_index()

  let view = winsaveview()
  let line = get(opts, 'line', view['lnum'])
  let org_row = get(opts, 'row', line - view['topline'] + 1)
  let org_col = get(opts, 'col', len(getline('.')) + 1) - 1

  let wininfo = getwininfo(win_getid())[0]
  let row = org_row + wininfo['winrow'] - 1
  let col = org_col + wininfo['wincol']

  let max_width = wininfo['width'] - org_col - 5
  let title_width = len(get(opts, 'title', '')) + 3
  let width = max(map(copy(a:texts), {_, v -> len(v)}) + [title_width]) + 2
  let width = min([width, max_width])

  let texts = copy(a:texts)
  if has_key(opts, 'border')
    let pseudo_border = printf(' ; %s ', iced#util#char_repeat(width - 4, '-'))

    if has_key(opts, 'title')
      let border_head = printf(' ; %s %s ',
            \           opts['title'],
            \           iced#util#char_repeat(width - len(opts['title']) - 5,
            \           '-'))
      let texts = [border_head] + texts + [pseudo_border]
    else
      let texts = [pseudo_border] + texts + [pseudo_border]
    endif
  endif

  let win_opts = {
        \ 'relative': 'editor',
        \ 'row': row,
        \ 'col': col,
        \ 'width': width,
        \ 'height': min([len(texts), g:iced#popup#max_height]),
        \ }

  call nvim_buf_set_lines(
        \ bufnr,
        \ index,
        \ index + g:iced#popup#max_height,
        \ 0,
        \ s:ensure_array_length(texts, g:iced#popup#max_height))
  let winid = nvim_open_win(bufnr, v:false, win_opts)
  call s:init_win(winid)

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

  if has_key(opts, 'filetyoe')
    call setbufvar(bufnr, '&filetype', opts['filetype'])
  endif

  if get(opts, 'auto_close', v:true)
    let time = get(opts, 'close_time', g:iced#popup#time)
    call timer_start(time, {-> iced#di#get('popup').close(winid)})
  endif

  return winid
endfunction

function! s:popup.close(window_id) abort
  if !s:is_supported() | return | endif
  if win_gotoid(a:window_id)
    silent execute ':q'
  endif
endfunction

function! iced#di#popup#neovim#build(container) abort
  if s:is_supported()
    call iced#buffer#init(s:bufname, funcref('s:initialize'))
  endif
  return s:popup
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
