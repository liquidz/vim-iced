let s:save_cpo = &cpoptions
set cpoptions&vim

let s:default_filetype = 'clojure'
let s:last_winid = -1

let s:popup = {
      \ 'env': 'neovim',
      \ }

let g:iced#popup#neovim#winhighlight = get(g:, 'iced#popup#neovim#winhighlight', 'Normal:NormalFloat')
let g:iced#popup#neovim#style = get(g:, 'iced#popup#neovim#style', 'minimal')

function! s:init_win(winid, opts) abort
  let context = get(a:opts, 'iced_context', {})
  let context['__lnum'] = line('.')
  if has_key(a:opts, 'moved')
    let context['__moved'] = a:opts['moved']
  endif

  call setwinvar(a:winid, 'iced_context', context)
  call setwinvar(a:winid, '&signcolumn', 'no')

  let bufnr = winbufnr(a:winid)
  call setbufvar(bufnr, '&filetype', get(a:opts, 'filetype', s:default_filetype))
  call setbufvar(bufnr, '&swapfile', 0)
  call setbufvar(bufnr, '&wrap', 0)
  call setbufvar(bufnr, '&winhl', g:iced#popup#neovim#winhighlight)
endfunction

function! s:popup.get_context(winid) abort
  return getwinvar(a:winid, 'iced_context', {})
endfunction

function! s:is_supported() abort
  return exists('*nvim_open_win')
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

function! s:popup.open(texts, ...) abort
  if !s:is_supported() | return | endif
  call iced#di#popup#neovim#moved()

  let bufnr = nvim_create_buf(0, 1)
  if bufnr < 0 | return | endif
  if type(a:texts) != v:t_list || empty(a:texts)
    return
  endif

  " TODO: support 'highlight' option
  let opts = get(a:, 1, {})
  if type(a:texts) != v:t_list || empty(a:texts)
    return
  endif

  let wininfo = getwininfo(win_getid())[0]
  let title_width = len(get(opts, 'title', '')) + 3
  let eol_col = len(getline('.')) + 1
  let width = max(map(copy(a:texts), {_, v -> len(v)}) + [title_width]) + 2

  let max_width = wininfo['width'] - eol_col - 5
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

  let min_height = len(texts)
  let height = min([min_height, g:iced#popup#max_height])

  if min_height + 5 >= &lines - &cmdheight
    throw 'vim-iced: too long texts to show in popup'
  endif

  " line
  let line = get(opts, 'line', winline())
  let line_type = type(line)
  if line_type == v:t_number
    let line = line + wininfo['winrow'] - 1
  elseif line_type == v:t_string && line ==# 'near-cursor'
    " NOTE: `+ 5` make the popup window not too low
    if winline() + height + 5 > &lines
      let line = winline() - height
    else
      let line = winline() + wininfo['winrow']
    endif
  endif

  " col
  let org_col = get(opts, 'col', eol_col)
  if type(org_col) == v:t_string
    if org_col ==# 'right'
      let org_col = wininfo['width'] - width
    else
      return iced#message#error('unexpected_error', printf('invalid column "%s"', org_col))
    endif
  else
    let org_col = org_col - 1
  endif
  let col = org_col + wininfo['wincol']

  let win_opts = {
        \ 'relative': 'editor',
        \ 'row': line,
        \ 'col': col,
        \ 'width': width,
        \ 'height': height,
        \ 'style': g:iced#popup#neovim#style,
        \ }

  call nvim_buf_set_lines(bufnr, 0, len(texts), 0, texts)
  let winid = nvim_open_win(bufnr, v:false, win_opts)
  call s:init_win(winid, opts)

  if has_key(opts, 'filetype')
    call setbufvar(bufnr, '&filetype', opts['filetype'])
  endif

  if get(opts, 'auto_close', v:true)
    let time = get(opts, 'close_time', g:iced#popup#time)
    call iced#di#get('timer').start(time, {-> iced#di#get('popup').close(winid)})
  endif

  let s:last_winid = winid
  return winid
endfunction

function! s:popup.move(window_id, options) abort
  let win_opts = nvim_win_get_config(a:window_id)
  let wininfo = getwininfo(win_getid())[0]

  if has_key(a:options, 'line')
    let win_opts['row'] = a:options['line'] + wininfo['winrow'] - 1
  endif

  if has_key(a:options, 'col')
    let win_opts['col'] = a:options['col'] + wininfo['wincol']
  endif

  call nvim_win_set_config(a:window_id, win_opts)
endfunction

function! s:popup.close(window_id) abort
  if !s:is_supported() | return | endif
  if win_gotoid(a:window_id)
    silent execute ':q'
  endif
  let s:last_winid = -1
endfunction

function! iced#di#popup#neovim#moved() abort
  if s:last_winid == -1 | return | endif
  let popup = iced#di#get('popup')
  let context = popup.get_context(s:last_winid)
  let moved = get(context, '__moved', '')
  let base_line = get(context, '__lnum', 0)
  let line = line('.')
  let col = col('.')

  " WARN: only supports 'any' and column list
  if empty(moved)
    return
  elseif type(moved) == v:t_string && moved ==# 'any'
    return popup.close(s:last_winid)
  elseif type(moved) == v:t_list && (line != base_line || col < moved[0] || col > moved[1])
    return popup.close(s:last_winid)
  endif
endfunction

function! iced#di#popup#neovim#build(container) abort
  return s:popup
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
