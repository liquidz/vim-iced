let s:save_cpo = &cpo
set cpo&vim

let s:ns_name = 'iced_virtual_text_namespace'
let s:ns = has('nvim')
      \ ? nvim_create_namespace(s:ns_name)
      \ : -1

let s:vim = {}
function! s:vim.set(...) abort
  return v:false
endfunction

function! s:vim.clear(...) abort
  return v:false
endfunction

let s:neovim = {}
function! s:neovim.set(text, ...) abort
  let opt = get(a:, 1, {})
  let buf = get(opt, 'buffer', bufnr('%'))
  let line = get(opt, 'line', line('.') -1)
  let hl = get(opt, 'highlight', 'Normal')
  call nvim_buf_set_virtual_text(buf, s:ns, line, [[a:text, hl]], {})

  if get(opt, 'auto_clear', v:false)
    let time = get(opt, 'clear_time', 3000)
    call timer_start(time, {-> nvim_buf_clear_namespace(buf, s:ns, line, line + 1)})
  endif
endfunction

function! s:neovim.clear(...) abort
  let opt = get(a:, 1, {})
  let buf = get(opt, 'buffer', bufnr('%'))
  let line = get(opt, 'line', line('.') -1)
  call nvim_buf_clear_namespace(buf, s:ns, line, line + 1)
endfunction

function! iced#state#virtual_text#definition() abort
  return {'start': {_ -> has('nvim') ? s:neovim : s:vim}}
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
