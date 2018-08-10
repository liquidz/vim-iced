let s:save_cpo = &cpo
set cpo&vim

function! s:indents_setting() abort
  if empty(g:iced#format#rule)
    return '{}'
  endif

  let rules = []
  for name in keys(g:iced#format#rule)
    call add(rules, printf('''%s %s', name, g:iced#format#rule[name]))
  endfor
  return printf('{:indents (merge cljfmt.core/default-indents {%s})}', join(rules, ' '))
endfunction

function! iced#nrepl#format#code(code) abort
  if !iced#nrepl#is_connected()
    return v:none
  endif

  let option = s:indents_setting()
  let code = iced#util#escape(a:code)
  let code = [
      \ '(require ''cljfmt.core)',
      \ printf('(cljfmt.core/reformat-string "%s" %s)', code, option),
      \ ]
  let code = printf('(do %s)', join(code, ' '))
  let resp = iced#nrepl#sync#send({
      \ 'id': iced#nrepl#eval#id(),
      \ 'op': 'eval',
      \ 'code': code,
      \ 'session': iced#nrepl#clj_session(),
      \ })

  if type(resp) == type({}) && has_key(resp, 'value')
    let val = resp['value']
    let val = val[1:len(val)-2]
    " NOTE: ignore '\\n' or '\\r'
    let val = substitute(val, '\%(\\\)\@<!\\n', "\n", 'g')
    let val = substitute(val, '\%(\\\)\@<!\\r', "\r", 'g')
    let val = iced#util#unescape(val)
    return val
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
