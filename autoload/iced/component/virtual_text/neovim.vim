let s:save_cpo = &cpoptions
set cpoptions&vim

let s:vt = {
      \ 'timer': '',
      \ 'ns': nvim_create_namespace('iced_virtual_text_namespace'),
      \ }

function! s:text_align_to_virt_text_pos(align) abort
  return get({'after': 'eol', 'right': 'right_align'}, a:align, 'eol')
endfunction

function! s:vt.set(text, ...) abort
  let opt = get(a:, 1, {})
  let buf = get(opt, 'buffer', bufnr('%'))
  let line = get(opt, 'line', line('.') -1)
  let hl = get(opt, 'highlight', 'Normal')
  let align = get(opt, 'align', 'after')

  call nvim_buf_clear_namespace(buf, self.ns, line, line + 1)
  call nvim_buf_set_extmark(buf, self.ns, line, 0, {
        \ 'virt_text': [[a:text, hl]],
        \ 'virt_text_pos': s:text_align_to_virt_text_pos(align)
        \ })

  if get(opt, 'auto_clear', v:false)
    let time = get(opt, 'clear_time', 3000)
    call self.timer.start(time, {-> nvim_buf_clear_namespace(buf, self.ns, line, line + 1)})
  endif
endfunction

function! s:vt.clear(...) abort
  let opt = get(a:, 1, {})
  let buf = get(opt, 'buffer', bufnr('%'))

  if empty(opt)
    call nvim_buf_clear_namespace(buf, self.ns, 1, line('$'))
  else
    let line = get(opt, 'line', line('.') -1)
    call nvim_buf_clear_namespace(buf, self.ns, line, line + 1)
  endif
endfunction

function! iced#component#virtual_text#neovim#start(this) abort
  call iced#util#debug('start', 'neovim virtual_text')
  let d = deepcopy(s:vt)
  let d['timer'] = a:this.timer
  return d
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
