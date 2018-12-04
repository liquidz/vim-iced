let s:save_cpo = &cpo
set cpo&vim

function! s:cache_key(var_name, opts) abort
  if !empty(a:var_name) && has_key(a:opts, 'file')
    return printf('%s:%s', a:var_name, a:opts['file'])
  endif
  return ''
endfunction

function! s:toggle_trace_var(resp, opts) abort
  if !has_key(a:resp, 'var-name') || !has_key(a:resp, 'var-status')
    return
  endif

  let var = a:resp['var-name']
  let cache_key = s:cache_key(var, a:opts)
  if a:resp['var-status'] ==# 'traced'
    let msg_key = 'start_to_trace'
    if !empty(cache_key)
      " delete existing sign
      let existing_sign_id = iced#cache#get(cache_key, -1)
      if existing_sign_id != -1
        call iced#sign#unplace(existing_sign_id)
      endif

      let sign_id = iced#sign#place('iced_trace', a:opts['lnum'], a:opts['file'])
      call iced#cache#set(cache_key, sign_id)
    endif
  else
    let msg_key = 'stop_to_trace'
    if !empty(cache_key)
      let sign_id = iced#cache#get(cache_key, -1)
      if sign_id != -1
        call iced#sign#unplace(sign_id)
        call iced#cache#delete(cache_key)
      endif
    endif
  endif

  call iced#message#info(msg_key, var)
endfunction

function! iced#nrepl#trace#toggle_var(symbol) abort
  let ns_name = iced#nrepl#ns#name()
  let symbol = a:symbol
  let opts = {}
  if empty(symbol)
    let symbol = expand('<cword>')
    let opts['lnum'] = getcurpos()[1]
    let opts['file'] = expand('%:p')
  endif
  call iced#nrepl#op#cider#toggle_trace_var(ns_name, symbol, {resp -> s:toggle_trace_var(resp, opts)})
endfunction

function! s:toggle_trace_ns(resp, ns_name) abort
  if !has_key(a:resp, 'ns-status')
    return
  endif

  let msg_key = (a:resp['ns-status'] ==# 'traced') ? 'start_to_trace' : 'stop_to_trace'
  call iced#message#info(msg_key, a:ns_name)
endfunction

function! iced#nrepl#trace#toggle_ns(ns_name) abort
  let ns_name = empty(a:ns_name) ? iced#nrepl#ns#name() : a:ns_name
  call iced#nrepl#op#cider#toggle_trace_ns(ns_name, {resp -> s:toggle_trace_ns(resp, ns_name)})
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
