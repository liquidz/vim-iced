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

function! iced#promise#wait(x, ...) abort
  let timeout = get(a:, 1, g:iced#promise#timeout_ms)
  let p = (type(a:x) == v:t_list) ? s:Promise.all(a:x) : a:x
  return s:Promise.wait(p, {
        \ 'timeout': timeout,
        \ 'interval': 1,
        \ })
endfunction

function! iced#promise#sync(fn, args, ...) abort
  let timeout = get(a:, 1, g:iced#promise#timeout_ms)
  let [result, error] = iced#promise#wait(iced#promise#call(a:fn, a:args), timeout)
  if error isnot# v:null
    throw string(error)
  endif

  return result
endfunction

function! iced#promise#resolve(x) abort
  return s:Promise.resolve(a:x)
endfunction

function! iced#promise#reject(x) abort
  return s:Promise.reject(a:x)
endfunction

function! iced#promise#is_promise(x) abort
  return s:Promise.is_promise(a:x)
endfunction

" For debugging
function! iced#promise#sleep(ms, ret) abort
  return s:Promise.new({resolve -> timer_start(a:ms, {-> resolve(a:ret)})})
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
