let s:save_cpo = &cpo
set cpo&vim

function! s:common_replace(s) abort
  let s = substitute(a:s, 'clojure.spec.alpha', 's', 'g')
  return substitute(s, 'clojure.core/', '', 'g')
endfunction

function! s:prn(v) abort
  return empty(a:v) ? 'nil' : a:v
endfunction

function! s:spec_format(spec) abort
  if type(a:spec) != v:t_list | return s:prn(a:spec) | endif

  let fn = a:spec[0]
  if fn ==# 'clojure.spec.alpha/fspec'
        \ || fn ==# 'clojure.spec.alpha/cat'
        \ || fn ==# 'clojure.spec.alpha/keys'
        \ || fn ==# 'clojure.spec.alpha/or'
    let res = []
    for kv in iced#util#partition(a:spec[1:], 2, v:false)
      let [k, v] = kv
      let v = (type(v) == v:t_list) ? s:spec_format(v) : s:prn(v)
      let indent = len(k) + 3
      call add(res, printf('  %s %s', k, iced#util#add_indent(indent, v)))
    endfor
    if len(res) == 1 && stridx(res[0], "\n") == -1
      return printf('(%s %s)', fn, iced#compat#trim(res[0]))
    else
      return printf("(%s\n%s)", fn, join(res, "\n"))
    endif
  " elseif fn ==# 'clojure.spec.alpha/keys' || fn ==# 'clojure.spec.alpha/or'
  "   let res = []
  "   for kv in iced#util#partition(a:spec[1:], 2, v:false)
  "     let [k, v] = kv
  "     let v = (type(v) == type([])) ? s:spec_format(v) : s:prn(v)
  "     call add(res, printf('%s %s', k, v))
  "   endfor
  "   " 15 = len('clojure.spec.alpha/') + len('(s/') + len(' ')
  "   let indent = len(fn) - 15
  "   return printf('(%s %s)', fn, iced#util#add_indent(indent, join(res, "\n")))
  elseif fn[0] ==# ':'
    return '[' . join(a:spec, ' ') . ']'
  endif

  return '(' . join(a:spec, ' ') . ')'
endfunction

function! iced#nrepl#spec#format(spec) abort
  let code = s:spec_format(a:spec)
  let code = s:common_replace(code)
  return code
endfunction

function! s:spec_form(resp) abort
  if !has_key(a:resp, 'spec-form')
    return iced#message#error('spec_form_error')
  endif

  let formatted = iced#nrepl#spec#format(a:resp['spec-form'])
  if empty(formatted)
    return iced#message#warn('no_spec')
  endif
  call iced#buffer#document#open(formatted, 'clojure')
endfunction

function! s:browse_spec(spec_name) abort
  call iced#nrepl#op#cider#spec_form(a:spec_name, funcref('s:spec_form'))
endfunction

function! s:spec_list(resp) abort
  if !has_key(a:resp, 'spec-list') || empty(a:resp['spec-list'])
    return iced#message#error('spec_list_error')
  endif

  let list = a:resp['spec-list']
  if len(list) == 1
    call s:browse_spec(list[0])
  else
    call iced#selector({
        \ 'candidates': list,
        \ 'accept': {_, spec_name -> s:browse_spec(spec_name)},
        \ })
  endif
endfunction

function! iced#nrepl#spec#list() abort
  call iced#nrepl#op#cider#spec_list(funcref('s:spec_list'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
