let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:vim(container) abort
  let d = {'container': a:container}

  function! d.set(text, ...) abort
    let opt = get(a:, 1, {})
    let popup_opts = {
          \ 'col': get(opt, 'col', col('$') + 3),
          \ 'highlight': get(opt, 'highlight', 'Comment'),
          \ }

    if get(opt, 'auto_clear', v:false)
      let popup_opts['moved'] = 'any'
    endif

    call self.container.get('popup').open([a:text], popup_opts)
  endfunction

  function! d.clear(...) abort
    call self.container.get('ex_cmd').silent_exe(':popupclear')
  endfunction

  return d
endfunction

let s:neovim = {}
let s:ns_name = 'iced_virtual_text_namespace'
let s:ns = has('nvim')
      \ ? nvim_create_namespace(s:ns_name)
      \ : -1

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

function! iced#di#virtual_text#build(container) abort
  return has('nvim') ? s:neovim : s:vim(a:container)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
