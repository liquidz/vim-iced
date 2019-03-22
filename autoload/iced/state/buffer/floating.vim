let s:save_cpo = &cpo
set cpo&vim

let s:floating = {
      \ 'bufname': 'iced_floating',
      \ 'state': {'buffer': {}},
      \ 'index': 0,
      \ 'max_height': 50,
      \ }

let g:iced#buffer#floating#time = get(g:, 'iced#buffer#floating#time', 3000)

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

function! s:floating.next_index() abort
  let t = self.index
  let self.index = (self.index > 10) ? 0 : self.index + 1
  return t * self.max_height
endfunction

function! s:initialize(bufnr) abort
  call setbufvar(a:bufnr, '&buflisted', 0)
  call setbufvar(a:bufnr, '&buftype', 'nofile')
  call setbufvar(a:bufnr, '&filetype', 'clojure')
  call setbufvar(a:bufnr, '&swapfile', 0)
  call setbufvar(a:bufnr, '&wrap', 0)
  call setbufvar(a:bufnr, '&winhl', 'Normal:Folded')
endfunction

function! s:floating.is_supported() abort
  return exists('*nvim_open_win')
endfunction

function! s:floating.close(window_id) abort
  if !self.is_supported() | return | endif
  if win_gotoid(a:window_id)
    silent execute ':q'
  endif
endfunction

function! s:floating.open(texts, ...) abort
  if !self.is_supported() | return | endif
  let bufnr = self.state.buffer.nr(self.bufname)
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
  let height = (height > self.max_height) ? self.max_height : height

  let win_opts = {
        \ 'relative': 'editor',
        \ 'row': row,
        \ 'col': col,
        \ 'width': width,
        \ 'height': height}
  call nvim_buf_set_lines(
        \ bufnr,
        \ index,
        \ index + self.max_height,
        \ 0,
        \ s:ensure_array_length(a:texts, self.max_height))
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
    let time = get(opts, 'close_time', g:iced#buffer#floating#time)
    call timer_start(time, {-> self.close(winid)})
  endif

  return winid
endfunction

function! iced#state#buffer#floating#start(params) abort
  let this = deepcopy(s:floating)
  let this['state']['buffer'] = a:params.require.buffer

  if exists('*nvim_open_win')
    call this.state.buffer.init(this.bufname, funcref('s:initialize'))
  endif

  return this
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
