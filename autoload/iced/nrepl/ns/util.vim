let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#ns#util#add_require_form(ns_code) abort
  let i = stridx(a:ns_code, '(:require')
  if i != -1
    return a:ns_code
  endif

  let i = strridx(a:ns_code, ')')
  let head = a:ns_code[0:i-1]
  let tail = strpart(a:ns_code, i)
  return printf("%s\n(:require)%s", head, tail)
endfunction

function! iced#nrepl#ns#util#add_namespace_to_require(ns_code, ns_name, ns_alias) abort
  let i = stridx(a:ns_code, '(:require')
  let i = stridx(a:ns_code, ')', i)

  let head = trim(a:ns_code[0:i-1])
  let tail = trim(strpart(a:ns_code, i))
  let body = (empty(a:ns_alias) ? a:ns_name : printf('[%s :as %s]', a:ns_name, a:ns_alias))
  let head_len = len(head)
  if head[head_len-8:head_len-1] ==# ':require'
    return printf('%s %s%s', head, body, tail)
  else
    return printf("%s\n%s%s", head, body, tail)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
