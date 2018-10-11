let s:save_cpo = &cpo
set cpo&vim

let s:decoder = {}

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
    let s = iced#compat#trim(decoded.rest)
  endwhile

  return {'value': list, 'rest': s[1:]}
endfunction

function! s:decode_dict(s) abort
  let dict = {}
  let s = a:s[1:]

  while s[0] !=# 'e'
    let k = s:decode(s)
    let v = s:decode(iced#compat#trim(k.rest))
    let dict[k.value] = v.value
    let s = iced#compat#trim(v.rest)
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

function! s:decoder.decode(s) abort
  let result = []
  let decoding = v:true
  let s = a:s

  while decoding
    let decoded = s:decode(s)
    if ! has_key(decoded, 'value')
      let decoding = v:false
    else
      call add(result, decoded.value)
      let s = iced#compat#trim(decoded.rest)

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
endfunction

function! iced#nrepl#bencode#vim#new() abort
  return s:decoder
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
