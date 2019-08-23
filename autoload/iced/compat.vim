let s:save_cpo = &cpoptions
set cpoptions&vim

function! iced#compat#appendbufline(expr, lnum, text) abort
  if has('nvim')
    " HACK: Workaround for https://github.com/liquidz/vim-iced/issues/65
    "       Probably caused by this nvim's bug
    "       https://github.com/neovim/neovim/issues/7756
    let view = winsaveview()
    try
      let buf = (type(a:expr) == v:t_string && a:expr ==# '%') ? 0 : a:expr
      let lnum = (a:lnum ==# '$') ? -1 : a:lnum
      return nvim_buf_set_lines(buf, lnum, lnum, 0, [a:text])
    finally
      call winrestview(view)
    endtry
  else
    return appendbufline(a:expr, a:lnum, a:text)
  endif
endfunction

function! iced#compat#deletebufline(expr, first, ...) abort
  let last = get(a:, 1, '')

  if has('nvim')
    let first = a:first - 1
    let buf = (type(a:expr) == v:t_string && a:expr ==# '%') ? 0 : a:expr

    if empty(last)
      let last = first + 1
    endif
    if last ==# '$'
      let last = -1
    endif

    return nvim_buf_set_lines(buf, first, last, 0, [])
  else
    if empty(last)
      return deletebufline(a:expr, a:first)
    else
      return deletebufline(a:expr, a:first, last)
    endif
  endif
endfunction

function! iced#compat#job_start(command, options) abort
  if has('nvim')
    let options = {}
    if has_key(a:options, 'out_cb')
      let options['on_stdout'] = {j,d,e -> a:options['out_cb'](e, join(d, ''))}
    endif
    return jobstart(a:command, options)
  else
    return job_start(a:command, a:options)
  endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
