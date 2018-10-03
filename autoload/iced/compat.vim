let s:save_cpo = &cpo
set cpo&vim

let s:V  = vital#iced#new()
let s:S  = s:V.import('Data.String')

function! iced#compat#trim(s) abort
  if has('nvim')
    return s:S.trim(a:s)
  else
    return trim(a:s)
  endif
endfunction

function! iced#compat#appendbufline(expr, lnum, text) abort
  if has('nvim')
    let lnum = (a:lnum ==# '$') ? -1 : a:lnum
    return nvim_buf_set_lines(a:expr, lnum, lnum, 0, [a:text])
  else
    return appendbufline(a:expr, a:lnum, a:text)
  endif
endfunction

function! iced#compat#deletebufline(expr, first, ...) abort
  let last = get(a:, 1, '')

  if has('nvim')
    if empty(last)
      let last = a:first
    endif
    if last ==# '$'
      let last = -1
    endif

    return nvim_buf_set_lines(a:expr, a:first, last, 0, [])
  else
    if empty(last)
      return deletebufline(a:expr, a:first)
    else
      return deletebufline(a:expr, a:first, last)
    endif
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
