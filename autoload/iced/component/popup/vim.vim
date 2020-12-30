let s:save_cpo = &cpoptions
set cpoptions&vim

let s:popup = {
      \ 'env': 'vim',
      \ 'config': {},
      \ }

function! s:init_win(winid, opts) abort
  call setwinvar(a:winid, 'iced_context', get(a:opts, 'iced_context', {}))
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

  let wininfo = getwininfo(win_getid())[0]
  let title_width = len(get(opts, 'title', '')) + 3
  let width = get(opts, 'width', -1)
  if width == -1
    let width = max(map(copy(a:texts), {_, v -> len(v)}) + [title_width]) + 1
  endif
  let min_height = len(a:texts)

  if min_height + 5 >= &lines - &cmdheight
    throw 'vim-iced: too long texts to show in popup'
  endif

  " line
  let line = get(opts, 'line', winline())
  let line_type = type(line)
  if line_type == v:t_number
    let line = line + wininfo['winrow'] - 1
  elseif line_type == v:t_string
    if line ==# 'near-cursor'
      " NOTE: `+ 5` make the popup window not too low
      if winline() + min_height + 5 > &lines
        let line = winline() - min_height - 1
      else
        let line = winline() + wininfo['winrow']
      endif
    elseif line ==# 'top'
      let line = wininfo['winrow']
    elseif line ==# 'bottom'
      let line = wininfo['winrow'] +  wininfo['height'] - min_height
    endif
  endif

  " col
  let org_col = get(opts, 'col', len(getline('.')) + 1)
  if type(org_col) == v:t_string
    if org_col ==# 'right'
      let org_col = wininfo['width'] - width
    elseif org_col ==# 'near-cursor'
      let org_col = wincol()
    else
      return iced#message#error('unexpected_error', printf('invalid column "%s"', org_col))
    endif
  else
    let org_col = org_col - 1
  endif
  " Align right when column goes off the screen
  if org_col + width > wininfo['width']
    let org_col = wininfo['width'] - width
  endif

  let col = org_col + wininfo['wincol']
  let max_width = &columns - wininfo['wincol'] - org_col + 1
  let win_opts = {
        \ 'line': line,
        \ 'col': col,
        \ 'minwidth': width,
        \ 'maxwidth': max_width,
        \ 'minheight': min_height,
        \ 'maxheight': self.config.max_height,
        \ }

  if get(opts, 'auto_close', v:true)
    let win_opts['time'] = get(opts, 'close_time', self.config.time)
  endif

  let Callback = get(opts, 'callback', '')
  if type(Callback) == v:t_func
    let win_opts['callback'] = {id, _ -> Callback(id)}
  endif

  call extend(win_opts, iced#util#select_keys(opts,
        \ ['highlight', 'border', 'borderchars', 'borderhighlight', 'title', 'moved', 'wrap']))

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

function! s:popup.settext(window_id, texts) abort
  call popup_settext(a:window_id, a:texts)
endfunction

function! s:popup.close(window_id) abort
  if !self.is_supported() | return | endif
  call popup_close(a:window_id)
endfunction

function! iced#component#popup#vim#start(this) abort
  call iced#util#debug('start', 'vim popup')
  let d = deepcopy(s:popup)
  let d.config = a:this.popup_config
  return d
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
