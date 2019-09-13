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
      let options['on_stdout'] = {j,d,e -> a:options['out_cb'](j, d)}
    endif
    if has_key(a:options, 'close_cb')
      let options['on_exit'] = {j,d,e -> a:options['close_cb'](j)}
    endif
    return jobstart(a:command, options)
  else
    return job_start(a:command, a:options)
  endif
endfunction

function! iced#compat#job_stop(job_id) abort
  if has('nvim')
    return jobstop(a:job_id)
  else
    return job_stop(a:job_id)
  endif
endfunction

function! iced#compat#is_job_id(x) abort
  if has('nvim')
    return type(a:x) == v:t_number && a:x > 0
  else
    return type(a:x) == v:t_job
  endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
