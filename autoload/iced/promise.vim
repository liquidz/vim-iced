let s:save_cpo = &cpoptions
set cpoptions&vim

let s:V = vital#iced#new()
let s:Promise = s:V.import('Async.Promise')

let s:default_timeout_ms = 3000
let g:iced#promise#timeout_ms = get(g:, 'iced#promise#timeout_ms', s:default_timeout_ms)

function! iced#promise#call(fn, args) abort
  let Fn = (type(a:fn) == v:t_func) ? a:fn : function(a:fn)
  let arg_type = type(a:args)

  if arg_type == v:t_list
    return s:Promise.new({resolve -> call(Fn, copy(a:args) + [resolve])})
  elseif arg_type == v:t_func
    return s:Promise.new({resolve -> call(Fn, a:args(resolve))})
  endif
  throw iced#message#get('invalid_format', a:args)
endfunction

function! iced#promise#wait(x) abort
  let p = (type(a:x) == v:t_list) ? s:Promise.all(a:x) : a:x
  return s:Promise.wait(p, {
        \ 'timeout': g:iced#promise#timeout_ms,
        \ 'interval': 1,
        \ })
endfunction

function! iced#promise#sync(fn, args) abort
  let [result, error] = iced#promise#wait(iced#promise#call(a:fn, a:args))
  if error isnot# v:null
    throw string(error)
  endif
  return result
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
