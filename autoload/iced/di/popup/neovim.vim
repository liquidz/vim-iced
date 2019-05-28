let s:save_cpo = &cpoptions
set cpoptions&vim

let s:bufname = 'iced_floating'
let s:default_filetype = 'clojure'

let s:popup = {
      \ 'env': 'neovim',
      \ 'index': 0,
      \ }

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

  let opts = get(a:, 1, {})
  let index = self.next_index()

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
        \ 'relative': 'editor',
        \ 'row': row,
        \ 'col': col,
        \ 'width': width,
        \ 'height': height}
  call nvim_buf_set_lines(
        \ bufnr,
        \ index,
        \ index + g:iced#popup#max_height,
        \ 0,
        \ iced#di#popup#ensure_array_length(a:texts, g:iced#popup#max_height))
  let winid = nvim_open_win(bufnr, v:false, win_opts)
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
