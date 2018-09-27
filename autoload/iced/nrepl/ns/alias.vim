let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:D = s:V.import('Data.Dict')

function! iced#nrepl#ns#alias#dict(code) abort
  let resp = iced#nrepl#op#iced#sync#ns_aliases(a:code)
  return has_key(resp, 'aliases') ? resp['aliases'] : {}
endfunction

function! iced#nrepl#ns#alias#find_existing_alias(ns_name) abort
  let aliases = iced#nrepl#op#refactor#sync#all_ns_aliases()
  let aliases = get(aliases, iced#nrepl#current_session_key(), {})

  for k in keys(aliases)
    if k ==# 'sut' | continue | endif
    for ns in aliases[k]
      if ns ==# a:ns_name
        return k
      endif
    endfor
  endfor
  return v:none
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
