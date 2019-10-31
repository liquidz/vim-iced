let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:vim(this) abort
  let d = {
        \ 'popup': a:this.popup,
        \ 'ex_cmd': a:this.ex_cmd,
        \ 'last_winid': v:null,
        \ }

  function! d.set(text, ...) abort
    let opt = get(a:, 1, {})
    let col = get(opt, 'col', col('$') + 3)
    let popup_opts = {
          \ 'iced_context': {'last_col': col},
          \ 'col': col,
          \ 'highlight': get(opt, 'highlight', 'Comment'),
          \ }

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

  function! d.clear(...) abort
    call self.ex_cmd.silent_exe(':popupclear')
  endfunction

  return d
endfunction

function! s:neovim(this) abort
  let d = {
        \ 'timer': a:this.timer,
        \ 'ns': nvim_create_namespace('iced_virtual_text_namespace'),
        \ }

  function! d.set(text, ...) abort
    let opt = get(a:, 1, {})
    let buf = get(opt, 'buffer', bufnr('%'))
    let line = get(opt, 'line', line('.') -1)
    let hl = get(opt, 'highlight', 'Normal')
    call nvim_buf_set_virtual_text(buf, self.ns, line, [[a:text, hl]], {})

    if get(opt, 'auto_clear', v:false)
      let time = get(opt, 'clear_time', 3000)
      call self.timer.start(time, {-> nvim_buf_clear_namespace(buf, s:ns, line, line + 1)})
    endif
  endfunction

  function! d.clear(...) abort
    let opt = get(a:, 1, {})
    let buf = get(opt, 'buffer', bufnr('%'))
    let line = get(opt, 'line', line('.') -1)
    call nvim_buf_clear_namespace(buf, self.ns, line, line + 1)
  endfunction

  return d
endfunction

function! iced#component#virtual_text#start(this) abort
  call iced#util#debug('start', 'virtual_text')
  return has('nvim') ? s:neovim(a:this) : s:vim(a:this)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
