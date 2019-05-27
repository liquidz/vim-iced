let s:save_cpo = &cpoptions
set cpoptions&vim

let s:popup = {
      \ 'env': 'vim',
      \ 'max_height': 50,
      \ }

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
  " FIXME
  return v:true
endfunction

function! s:popup.open(texts, ...) abort
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
  let height = (height > self.max_height) ? self.max_height : height

  let win_opts = {
        \ 'line': row+1,
        \ 'col': col+1,
        \ 'maxwidth': width,
        \ 'maxheight': height,
        \ }

  let winid = popup_create(
       \ s:ensure_array_length(a:texts, self.max_height),
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
