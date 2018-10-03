let s:save_cpo = &cpo
set cpo&vim

function! s:parse_aliases_value(v) abort
  let result = {}
  if empty(a:v) | return result | endif
  let v = trim(a:v)
  for pair in split(trim(a:v), ',')
    let [alias, name] = split(pair, '(')
    let result[trim(alias)] = split(substitute(name, '[()]', '', 'g'), ' \+')
  endfor
  return result
endfunction

function! s:ensure_tuple(ls) abort
  let l = len(a:ls)
  if l == 2
    return a:ls
  elseif l > 0
    return [a:ls[0], '']
  endif
  return ['', '']
endfunction

function! s:namespace_aliases(resp) abort
  let result = {}
  let aliases = a:resp['namespace-aliases']
  let aliases = strpart(aliases, 1, len(aliases)-3)
  for grp in split(aliases, '}')
    let [k, v] = s:ensure_tuple(split(grp, '{'))
    let k = strpart(trim(k), 1)
    let result[k] = s:parse_aliases_value(v)
  endfor
  return result
endfunction

function! iced#nrepl#op#refactor#sync#all_ns_aliases() abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let resp = iced#nrepl#sync#send({
      \ 'op': 'namespace-aliases',
      \ 'session': iced#nrepl#current_session(),
      \ })
  return s:namespace_aliases(resp)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
