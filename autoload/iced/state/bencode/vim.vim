let s:save_cpo = &cpo
set cpo&vim

let s:bencode = {}

" s:bencode.encode {{{
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
  if t == v:t_number
    return s:encode_number(a:v)
  elseif t == v:t_string
    return s:encode_string(a:v)
  elseif t == v:t_list
    return s:encode_list(a:v)
  elseif t == v:t_dict
    return s:encode_dict(a:v)
  elseif t == 7 " v:none or v:null
    return s:encode_string('')
  endif
endfunction

function! s:bencode.encode(v) abort
  return s:encode(a:v)
endfunction " }}}

" s:bencode.decode {{{
function! s:decode_string(s) abort
  let i = stridx(a:s, ':')
  if i == -1
    throw 'Failed to parse string token'
  endif
  let len = str2nr(a:s[0:i-1])
  return {'value': a:s[i+1:i+len], 'rest': a:s[i+len+1:]}
endfunction

function! s:decode_integer(s) abort
  let i = stridx(a:s, 'e')
  if i == -1
    throw 'Failed to parse integer token'
  endif
  return {'value': str2nr(a:s[1:i-1]), 'rest': a:s[i+1:]}
endfunction

function! s:decode_list(s) abort
  let list = []
  let s = a:s[1:]

  while s[0] !=# 'e'
    let decoded = s:decode(s)
    call add(list, decoded.value)
    let s = trim(decoded.rest)
  endwhile

  return {'value': list, 'rest': s[1:]}
endfunction

function! s:decode_dict(s) abort
  let dict = {}
  let s = a:s[1:]

  while s[0] !=# 'e'
    let k = s:decode(s)
    let v = s:decode(trim(k.rest))
    let dict[k.value] = v.value
    let s = trim(v.rest)
  endwhile

  return {'value': dict, 'rest': s[1:]}
endfunction

function! s:decode(s) abort
  if a:s[0] ==# 'i'
    return s:decode_integer(a:s)
  elseif a:s[0] =~# '[0-9]'
    return s:decode_string(a:s)
  elseif a:s[0] ==# 'l'
    return s:decode_list(a:s)
  elseif a:s[0] ==# 'd'
    return s:decode_dict(a:s)
  else
    throw 'Failed to parse bencode.'
  endif
endfunction

function! s:bencode.decode(s) abort
  let result = []
  let decoding = v:true
  let s = a:s

  while decoding
    let decoded = s:decode(s)
    if ! has_key(decoded, 'value')
      let decoding = v:false
    else
      call add(result, decoded.value)
      let s = trim(decoded.rest)

      if s ==# ''
        let decoding = v:false
      end
    endif
  endwhile

  if len(result) == 1
    return result[0]
  else
    return result
  endif
endfunction " }}}

function! iced#state#bencode#vim#start(_) abort
  return s:bencode
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim:fdm=marker:fdl=0
