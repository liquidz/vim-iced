let s:save_cpo = &cpoptions
set cpoptions&vim

let s:popup = {
      \ 'env': 'vim',
      \ }

function! s:popup.is_supported() abort
  return exists('*popup_create')
endfunction

function! s:popup.open(texts, ...) abort
  echom 'FIXME opening'
  let opts = get(a:, 1, {})
  if type(a:texts) != v:t_list || empty(a:texts)
    return
  endif

  let view = winsaveview()
  let line = get(opts, 'line', view['lnum'])
  let row = get(opts, 'row', line - view['topline'] + 1)
  let col = get(opts, 'col', len(getline('.')) + 1)

  let max_width = &columns - col - 5
  let width = max(map(copy(a:texts), {_, v -> len(v)})) + 2
  let width = (width > max_width) ? max_width : width
  let height = len(a:texts)
  let height = (height > g:iced#popup#max_height) ? g:iced#popup#max_height : height

  let win_opts = {
        \ 'line': row + 1,
        \ 'col': col + 1,
        \ 'maxwidth': width + 1,
        \ 'maxheight': height,
        \ }

  if get(opts, 'auto_close', v:true)
    let win_opts['time'] = get(opts, 'close_time', g:iced#popup#time)
  endif

  let winid = popup_create(
       \ iced#di#popup#ensure_array_length(a:texts, g:iced#popup#max_height),
       \ win_opts)

  let bufnr = winbufnr(winid)
  call setbufvar(bufnr, '&filetype', 'clojure')

  return winid
endfunction

function! s:popup.close(window_id) abort
  call popup_close(a:window_id)
endfunction

function! iced#di#popup#vim#build(container) abort
  return s:popup
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
