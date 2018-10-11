let s:save_cpo = &cpo
set cpo&vim

let s:decoder = has('python3')
      \ ? iced#nrepl#bencode#python#new()
      \ : iced#nrepl#bencode#vim#new()

function! s:encode_string(s) abort
  return printf('%d:%s', strlen(a:s), a:s)
endfunction

function! s:encode_number(i) abort
  return printf('i%de', a:i)
endfunction

function! s:encode_list(l) abort
  let result = []
  for v in a:l
    call add(result, s:encode(v))
  endfor
  return printf('l%se', join(result, ''))
endfunction

function! s:encode_dict(d) abort
  let result = []
  for k in keys(a:d)
    call add(result, s:encode(k))
    call add(result, s:encode(a:d[k]))
  endfor
  return printf('d%se', join(result, ''))
endfunction

function! s:encode(v) abort
  let t = type(a:v)
  if t == 0
    return s:encode_number(a:v)
  elseif t == 1
    return s:encode_string(a:v)
  elseif t == 3
    return s:encode_list(a:v)
  elseif t == 4
    return s:encode_dict(a:v)
  elseif t == 7
    return s:encode_string('')
  endif
endfunction

function! iced#nrepl#bencode#encode(v) abort
  return s:encode(a:v)
endfunction

function! iced#nrepl#bencode#decode(s) abort
  return s:decoder.decode(a:s)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
