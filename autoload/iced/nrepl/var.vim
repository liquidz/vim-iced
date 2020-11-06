let s:save_cpo = &cpoptions
set cpoptions&vim

function! iced#nrepl#var#cword() abort
  let isk = &iskeyword
  try
    let &iskeyword = printf('%s,#,%%,&,39', isk)
    return expand('<cword>')
  finally
    let &iskeyword = isk
  endtry
endfunction

function! s:expand_ns_alias(ns_name, symbol) abort
  let i = stridx(a:symbol, '/')
  if i == -1 || a:symbol[0] ==# ':'
    return a:symbol
  endif

  let alias_dict = iced#nrepl#ns#alias_dict(a:ns_name)
  let ns = a:symbol[0:i-1]
  let ns = get(alias_dict, ns, ns)

  return printf('%s/%s', ns, strpart(a:symbol, i+1))
endfunction

function! s:assoc_ns_for_special_form(resp) abort
  if get(a:resp, 'special-form', '') ==# 'true'
    let resp = copy(a:resp)
    let resp['ns'] = 'clojure.core'
    return resp
  endif
  return a:resp
endfunction

function! s:extract_var_name(eval_resp, callback) abort
  if has_key(a:eval_resp, 'err') | return iced#nrepl#eval#err(a:eval_resp['err']) | endif
  if !has_key(a:eval_resp, 'value') | return iced#message#error('not_found') | endif

  let var = a:eval_resp['value']
  if stridx(var, '#''') == 0
    let var = substitute(var, '^#''', '', '')
    let i = stridx(var, '/')
    let ns = var[0:i-1]
    let var_name = strpart(var, i+1)
  elseif stridx(var, '#multifn') == 0
    let var_name = substitute(var, '^#multifn\[', '', '')
    let var_name = substitute(var_name, ' [^ ]\+\]$', '', '')
    let ns = iced#nrepl#ns#name_by_buf()
    let var = printf('%s/%s', ns, var_name)
  endif

  call a:callback({
        \ 'qualified_var': var,
        \ 'ns': ns,
        \ 'name': var_name,
        \ })
endfunction

""
" If a:0 == 1, first argument is a callback function.
" If a:0 == 2, first argument is a symbol string and second is a callback function.
function! iced#nrepl#var#get(...) abort
  if !iced#nrepl#is_connected()
    return iced#message#error('not_connected')
  endif

  let symbol = ''
  let Callback = ''

  if a:0 == 1
    let symbol = iced#nrepl#var#cword()
    let Callback = get(a:, 1, '')
  elseif a:0 == 2
    let symbol = get(a:, 1, '')
    let symbol = empty(symbol) ? iced#nrepl#var#cword() : symbol
    let Callback = get(a:, 2, '')
  else
    return
  endif

  " Remove quote if exists
  let symbol = trim(symbol, "'")

  if type(Callback) != v:t_func
    return
  endif

  let ns_name = iced#nrepl#ns#name()
  if iced#nrepl#current_session_key() ==# 'cljs'
    let symbol = s:expand_ns_alias(ns_name, symbol)
  endif

  if iced#nrepl#is_supported_op('info')
    call iced#nrepl#op#cider#info(ns_name, symbol, {resp -> Callback(s:assoc_ns_for_special_form(resp))})
  else
    let code = printf('#''%s', symbol)
    let pos = getcurpos()
    let option = {'line': pos[1], 'column': pos[2]}
    call iced#nrepl#eval(code, option, {resp -> s:extract_var_name(resp, Callback)})
  endif
endfunction

function! iced#nrepl#var#extract_by_current_top_list(callback) abort
  let ret = iced#paredit#get_current_top_object('(', ')')
  let code = get(ret, 'code')
  if empty(code) | return iced#message#error('finding_code_error') | endif

  " for defmulti, defmethod
  let res = matchlist(code, '^([\r\n\t ]*\(defmulti\|defmethod\)\s\+\([^ \r\n]\+\)')
  if len(res) >= 3
    let code = res[2]
  endif

  let pos = ret['curpos']
  let option = {'line': pos[1], 'column': pos[2]}
  call iced#nrepl#eval(code, option, {resp ->
        \ s:extract_var_name(resp, a:callback)})
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
