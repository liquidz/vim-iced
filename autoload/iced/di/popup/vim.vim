let s:save_cpo = &cpoptions
set cpoptions&vim

let s:popup = {
      \ 'env': 'vim',
      \ }

function! s:init_win(winid, opts) abort
  call setwinvar(a:winid, 'iced_context', get(a:opts, 'iced_context', {}))
  call setwinvar(a:winid, '&signcolumn', 'no')
  call setwinvar(a:winid, '&breakindent', 1)

  let bufnr = winbufnr(a:winid)
  if has_key(a:opts, 'filetype')
    call setbufvar(bufnr, '&filetype', a:opts['filetype'])
  endif
endfunction

function! s:popup.is_supported() abort
  return exists('*popup_create')
endfunction

function! s:popup.get_context(winid) abort
  return getwinvar(a:winid, 'iced_context', {})
endfunction

function! s:popup.open(texts, ...) abort
  if !self.is_supported() | return | endif

  let opts = get(a:, 1, {})
  if type(a:texts) != v:t_list || empty(a:texts)
    return
  endif

  let view = winsaveview()
  let line = get(opts, 'line', view['lnum'])
  let org_row = get(opts, 'row', line - view['topline'] + 1)
  let org_col = get(opts, 'col', len(getline('.')) + 1) - 1

  let wininfo = getwininfo(win_getid())[0]
  let row = org_row + wininfo['winrow'] - 1
  let col = org_col + wininfo['wincol']

  let max_width = &columns - wininfo['wincol'] - org_col
  let title_width = len(get(opts, 'title', '')) + 3
  let width = max(map(copy(a:texts), {_, v -> len(v)}) + [title_width]) + 1

  let win_opts = {
        \ 'line': row,
        \ 'col': col,
        \ 'minwidth': width,
        \ 'maxwidth': max_width,
        \ 'minheight': len(a:texts),
        \ 'maxheight': g:iced#popup#max_height,
        \ }

  if get(opts, 'auto_close', v:true)
    let win_opts['time'] = get(opts, 'close_time', g:iced#popup#time)
  endif

  call extend(win_opts, iced#util#select_keys(opts,
        \ ['highlight', 'border', 'borderhighlight', 'title', 'moved']))

  let winid = popup_create(a:texts, win_opts)
  call s:init_win(winid, opts)

  return winid
endfunction

function! s:popup.move(window_id, options) abort
  let options = copy(a:options)
  let wininfo = getwininfo(win_getid())[0]

  if has_key(options, 'line')
    let options['line'] = options['line'] + wininfo['winrow'] - 1
  endif

  if has_key(options, 'col')
    let options['col'] = options['col'] + wininfo['wincol']
  endif

  call popup_move(a:window_id, options)
endfunction

function! s:popup.close(window_id) abort
  if !self.is_supported() | return | endif
  call popup_close(a:window_id)
endfunction

function! iced#di#popup#vim#build(container) abort
  return s:popup
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
