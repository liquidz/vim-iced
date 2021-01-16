let s:save_cpo = &cpoptions
set cpoptions&vim

let s:vt = {
      \ 'popup': '',
      \ 'ex_cmd': '',
      \ 'last_winid': v:null,
      \ }

function! s:vt.set(text, ...) abort
  let opt = get(a:, 1, {})
  let wininfo = getwininfo(win_getid())[0]

  " Close last virtual text window if same position
  let ctx = self.popup.get_context(self.last_winid)
  if has_key(ctx, 'last_col') && col == ctx['last_col']
    call self.popup.close(self.last_winid)
  endif

  " col
  let col = get(opt, 'col', col('$') + 3)
  " line
  let line = get(opt, 'line', winline())
  " width
  let max_width = wininfo['width'] - col
  if max_width < 0
    let col = wincol()
    let max_width = wininfo['width'] - col
    let line += 1
  endif
  let text = iced#util#shorten(a:text, max_width)

  let popup_opts = {
        \ 'iced_context': {'last_col': col},
        \ 'col': col,
        \ 'line': line,
        \ 'highlight': get(opt, 'highlight', 'Comment'),
        \ }
  if get(opt, 'auto_clear', v:false)
    let popup_opts['moved'] = 'any'
    let popup_opts['auto_close'] = v:false
  endif

  let self.last_winid = self.popup.open([text], popup_opts)
  return self.last_winid
endfunction

function! s:vt.clear(...) abort
  call self.ex_cmd.silent_exe(':popupclear')
endfunction

function! iced#component#virtual_text#vim#start(this) abort
  call iced#util#debug('start', 'vim virtual_text')
  let d = deepcopy(s:vt)
  let d['popup'] = a:this.popup
  let d['ex_cmd'] = a:this.ex_cmd
  return d
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
