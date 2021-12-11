let s:save_cpo = &cpoptions
set cpoptions&vim

let s:default_filetype = 'clojure'
let s:default_border = [' ', '=' , ' ', ' ', ' ', '=', ' ', ' ']
let s:last_winid = -1

let s:popup = {
      \ 'env': 'neovim',
      \ 'config': {},
      \ 'groups': {},
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
  " HACK: To avoid vim-lsp activation
  call setbufvar(bufnr, '&buftype', 'terminal')

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

function! s:auto_close(winid, opt) abort
  call iced#system#get('popup').close(a:winid)

  let Callback = get(a:opt, 'callback', '')
  if type(Callback) == v:t_func
    call Callback(a:winid)
  endif
endfunction

function! s:popup.open(texts, ...) abort
  if !s:is_supported() | return | endif
  call iced#component#popup#neovim#moved()

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
  let max_width = float2nr(wininfo['width'] * 0.95)

  " simulate `wrap` option because nvim's floating window
  " does not support `max_height`
  let texts = []
  if get(opts, 'wrap', 1)
    for text in a:texts
      if len(text) > max_width
        let texts += iced#util#split_by_length(text, max_width)
      else
        let texts += [text]
      endif
    endfor
  else
    let texts = copy(a:texts)
  endif

  let title_width = len(get(opts, 'title', '')) + 3
  let eol_col = len(getline('.')) + 1
  let width = get(opts, 'width', -1)
  if width == -1
    let width = max(map(copy(texts), {_, v -> len(v)}) + [title_width]) + 2
  endif
  if width > max_width
    let width = max_width
  endif

  if has_key(opts, 'border') && !has('nvim-0.5')
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
  let height = min([min_height, self.config.max_height])

  if min_height + 5 >= &lines - &cmdheight
    throw 'vim-iced: too long texts to show in popup'
  endif

  " line
  let line = get(opts, 'line', winline())
  let line_type = type(line)
  if line_type == v:t_number
    let line = line - 1 + wininfo['winrow'] - 1
  elseif line_type == v:t_string
    if line ==# 'near-cursor'
      " NOTE: `+ 5` make the popup window not too low
      if winline() + height + 5 > &lines
        let line = winline() - height
        if has_key(opts, 'border') && has('nvim-0.5')
          let line -= 2
        endif
      else
        let line = winline() + wininfo['winrow'] - 1
      endif
    elseif line ==# 'top'
      let line = wininfo['winrow'] - 1
    elseif line ==# 'bottom'
      let line = wininfo['winrow'] +  wininfo['height'] - min_height - 1
    endif
  endif

  " col
  let org_col = get(opts, 'col', eol_col)
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
  let col = org_col + wininfo['wincol']

  let win_opts = {
        \ 'relative': 'editor',
        \ 'row': line,
        \ 'col': col,
        \ 'width': width,
        \ 'height': height,
        \ 'style': g:iced#popup#neovim#style,
        \ }

  if has_key(opts, 'border') && has('nvim-0.5')
    let border = get(opts, 'border')
    let win_opts['border'] = empty(border)
          \ ? s:default_border
          \ : border
  endif

  " Open popup
  call nvim_buf_set_lines(bufnr, 0, len(texts), 0, texts)
  let winid = nvim_open_win(bufnr, v:false, win_opts)
  call s:init_win(winid, opts)

  if has_key(opts, 'filetype')
    call setbufvar(bufnr, '&filetype', opts['filetype'])
  endif

  if get(opts, 'auto_close', v:true)
    let time = get(opts, 'close_time', self.config.time)
    call iced#system#get('timer').start(time, {-> s:auto_close(winid, opts)})
  endif

  " Popup group
  let popup_group = get(opts, 'group')
  if ! empty(popup_group)
    let opened_winid = get(self.groups, popup_group)
    if ! empty(opened_winid)
      call self.close(opened_winid)
    endif
    let self.groups[popup_group] = winid
  endif

  let s:last_winid = winid
  return winid
endfunction

function! s:popup.move(window_id, options) abort
  let win_opts = nvim_win_get_config(a:window_id)
  let win_opts['relative'] = 'editor'
  let wininfo = getwininfo(win_getid())[0]

  if has_key(a:options, 'line')
    let win_opts['row'] = a:options['line'] + wininfo['winrow'] - 1
  endif

  if has_key(a:options, 'col')
    let win_opts['col'] = a:options['col'] + wininfo['wincol']
  endif

  call nvim_win_set_config(a:window_id, win_opts)
endfunction

function! s:popup.settext(window_id, texts) abort
  let bufnr = winbufnr(a:window_id)
  let info = getbufinfo(bufnr)[0]
  let variables = get(info, 'variables', {})
  let linecount = get(variables, 'linecount', len(a:texts))
  call nvim_buf_set_lines(bufnr, 0, linecount, 0, a:texts)
endfunction

function! s:popup.close(window_id) abort
  if !s:is_supported() | return | endif
  if win_gotoid(a:window_id)
    silent execute ':q'
  endif
  let s:last_winid = -1
endfunction

function! iced#component#popup#neovim#moved() abort
  if s:last_winid == -1 | return | endif
  let context = s:popup.get_context(s:last_winid)
  let moved = get(context, '__moved', '')
  let base_line = get(context, '__lnum', 0)
  let line = line('.')
  let col = col('.')

  " WARN: only supports 'any' and column list
  if empty(moved)
    return
  elseif type(moved) == v:t_string && moved ==# 'any'
    return s:popup.close(s:last_winid)
  elseif type(moved) == v:t_list && (line != base_line || col < moved[0] || col > moved[1])
    return s:popup.close(s:last_winid)
  endif
endfunction

" NOTE: Neovim does not have `moved` option for floating window.
"       So vim-iced must close floating window explicitly.
function! iced#component#popup#neovim#register_moved_autocmd(bufnr) abort
  silent execute printf('au! * <buffer=%s>', a:bufnr)
  silent execute printf('au CursorMoved <buffer=%s> call iced#component#popup#neovim#moved()', a:bufnr)
  silent execute printf('au CursorMovedI <buffer=%s> call iced#component#popup#neovim#moved()', a:bufnr)
endfunction

function! iced#component#popup#neovim#start(this) abort
  call iced#util#debug('start', 'neovim popup')
  let d = deepcopy(s:popup)
  let d.config = a:this.popup_config
  return d
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
