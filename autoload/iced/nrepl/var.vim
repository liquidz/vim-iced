let s:save_cpo = &cpoptions
set cpoptions&vim

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
    let symbol = expand('<cword>')
    let Callback = get(a:, 1, '')
  elseif a:0 == 2
    let symbol = get(a:, 1, '')
    let symbol = empty(symbol) ? expand('<cword>') : symbol
    let Callback = get(a:, 2, '')
  else
    return
  endif

  if type(Callback) != v:t_func
    return
  endif

  let ns_name = iced#nrepl#ns#name()
  if iced#nrepl#current_session_key() ==# 'cljs'
    let symbol = s:expand_ns_alias(ns_name, symbol)
  endif

  call iced#nrepl#op#cider#info(ns_name, symbol, Callback)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
