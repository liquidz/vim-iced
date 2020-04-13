let s:save_cpo = &cpoptions
set cpoptions&vim

let s:vt = {
      \ 'popup': '',
      \ 'ex_cmd': '',
      \ 'last_winid': v:null,
      \ }

function! s:vt.set(text, ...) abort
  let opt = get(a:, 1, {})
  let col = get(opt, 'col', col('$') + 3)
  let popup_opts = {
        \ 'iced_context': {'last_col': col},
        \ 'col': col,
        \ 'highlight': get(opt, 'highlight', 'Comment'),
        \ }

  if has_key(opt, 'line')
    let popup_opts['line'] = opt.line
  endif

  if get(opt, 'auto_clear', v:false)
    let popup_opts['moved'] = 'any'
    let popup_opts['auto_close'] = v:false
  endif

  " Close last virtual text window if same position
  let ctx = self.popup.get_context(self.last_winid)
  if has_key(ctx, 'last_col') && col == ctx['last_col']
    call self.popup.close(self.last_winid)
  endif

  let self.last_winid = self.popup.open([a:text], popup_opts)
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
