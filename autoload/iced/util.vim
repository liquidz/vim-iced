let s:save_cpo = &cpo
set cpo&vim

let g:iced#debug = v:false

function! iced#util#is_function(v) abort
  return type(a:v) == 2
endfunction

function! iced#util#echo_messages(s) abort
  for line in split(a:s, '\r\?\n')
    echomsg line
  endfor
endfunction

function! iced#util#wait(pred, timeout_ms) abort
  let t = 0
  while a:pred() && t < a:timeout_ms
    sleep 1m
    let t = t + 1
  endwhile

  return (t < a:timeout_ms)
endfunction

function! iced#util#escape(s) abort
  let s = a:s
  let s = substitute(s, '\\', '\\\\', 'g')
  let s = substitute(s, '"', '\\"', 'g')
  return s
endfunction

function! iced#util#unescape(s) abort
  let s = a:s
  let s = substitute(s, '\\"', '"', 'g')
  let s = substitute(s, '\\\\', '\\', 'g')
  return s
endfunction

function! iced#util#ensure_array(x) abort
  return (type(a:x) == type([]) ? a:x : [a:x])
endfunction

function! iced#util#debug(x) abort
  if g:iced#debug
    echom printf('DEBUG: %s', a:x)
  endif
endfunction

function! iced#util#save_cursor_position() abort
  return {
      \ 'bufnr': bufnr('%'),
      \ 'view': winsaveview(),
      \ }
endfunction

function! iced#util#restore_cursor_position(pos) abort
  silent exe printf('b %d', a:pos['bufnr'])
  silent call winrestview(a:pos['view'])
endfunction

function! iced#util#has_status(resp, status) abort
  for resp in iced#util#ensure_array(a:resp)
    for status in get(resp, 'status', [v:none])
      if status ==# a:status
        return v:true
      endif
    endfor
  endfor
  return v:false
endfunction

function! s:char_repeat(n, c) abort
  let ret = ''
  for _ in range(a:n) | let ret = ret . a:c | endfor
  return ret
endfunction

function! iced#util#add_indent(n, s) abort
  let spc = s:char_repeat(a:n, ' ')
  return substitute(a:s, '\r\?\n', "\n".spc, 'g')
endfunction

function! iced#util#del_indent(n, s) abort
  let spc = s:char_repeat(a:n, ' ')
  return substitute(a:s, '\r\?\n'.spc, "\n", 'g')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
