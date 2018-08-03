let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('iced')
let s:L = s:V.import('Data.List')

function! s:extract_ns(s) abort
  let start = stridx(a:s, '[')
  let end = stridx(a:s, ']')
  return a:s[start+1:end-1]
endfunction

function! s:parse_to_alias_dict(resp) abort
  if !has_key(a:resp, 'value') || a:resp['value'][0] !=# '{'
    return {}
  endif

  let value = a:resp['value']
  let value = value[1:len(value)-2]

  let result = {}
  let ls = split(value, ',\? ')
  while !empty(ls)
    let k = s:L.shift(ls)
    let v = s:extract_ns(s:L.shift(ls))
    let result[k] = v
  endwhile

  return result
endfunction

function! iced#complete#alias#dict(ns) abort
  let code = printf('(ns-aliases ''%s)', a:ns)
  let resp = iced#nrepl#sync#send({
      \ 'op': 'eval',
      \ 'code': code,
      \ 'session': iced#nrepl#current_session(),
      \ })
  return s:parse_to_alias_dict(resp)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
