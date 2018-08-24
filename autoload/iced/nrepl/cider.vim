let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#cider#info(symbol, callback) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return
  endif

  call iced#nrepl#send({
      \ 'op': 'info',
      \ 'session': iced#nrepl#current_session(),
      \ 'symbol': a:symbol,
      \ 'ns': iced#nrepl#ns#name(),
      \ 'callback': a:callback,
      \ })
endfunction

function! iced#nrepl#cider#ns_path(ns, callback) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return
  endif

  call iced#nrepl#send({
      \ 'op': 'ns-path',
      \ 'session': iced#nrepl#current_session(),
      \ 'ns': a:ns,
      \ 'callback': a:callback,
      \ })
endfunction

function! iced#nrepl#cider#format_code(code, callback) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return
  endif

  call iced#nrepl#send({
      \ 'op': 'format-code',
      \ 'session': iced#nrepl#current_session(),
      \ 'code': a:code,
      \ 'callback': a:callback,
      \ })
endfunction

function! iced#nrepl#cider#format_code(code, callback) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return
  endif

  call iced#nrepl#send({
      \ 'op': 'format-code',
      \ 'session': iced#nrepl#current_session(),
      \ 'code': a:code,
      \ 'callback': a:callback,
      \ })
endfunction

let s:test_buffer = []

function! s:test_handler(resp) abort
  call extend(s:test_buffer, (type(a:resp) == type([]) ? a:resp : [a:resp]))
  return s:test_buffer
endfunction

function! s:tested(resp) abort
  let result = copy(s:test_buffer)
  let s:test_buffer = []
  return result
endfunction

function! iced#nrepl#cider#test_var(test_var, callback) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return
  endif

  call iced#nrepl#send({
      \ 'op': 'test',
      \ 'session': iced#nrepl#current_session(),
      \ 'id': iced#nrepl#eval#id(),
      \ 'ns': iced#nrepl#ns#name(),
      \ 'tests': [a:test_var],
      \ 'callback': {resp -> a:callback(s:tested(resp))},
      \ })
endfunction

function! iced#nrepl#cider#test_ns(test_ns, callback) abort
  if iced#nrepl#is_connected()
    call iced#nrepl#send({
        \ 'op': 'test',
        \ 'session': iced#nrepl#current_session(),
        \ 'id': iced#nrepl#eval#id(),
        \ 'ns': a:test_ns,
        \ 'callback': {resp -> a:callback(s:tested(resp))},
        \ })
  endif
endfunction

function! iced#nrepl#cider#retest(callback) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return
  endif

  call iced#nrepl#send({
      \ 'op': 'retest',
      \ 'session': iced#nrepl#current_session(),
      \ 'id': iced#nrepl#eval#id(),
      \ 'callback': {resp -> a:callback(s:tested(resp))},
      \ })
endfunction

function! iced#nrepl#cider#test_all(callback) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return
  endif

  call iced#nrepl#send({
      \ 'op': 'test-all',
      \ 'session': iced#nrepl#current_session(),
      \ 'id': iced#nrepl#eval#id(),
      \ 'callback': {resp -> a:callback(s:tested(resp))},
      \ })
endfunction

function! iced#nrepl#cider#undef(symbol, callback) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return
  endif

  call iced#nrepl#send({
      \ 'op': 'undef',
      \ 'session': iced#nrepl#current_session(),
      \ 'ns': iced#nrepl#ns#name(),
      \ 'symbol': a:symbol,
      \ 'callback': a:callback,
      \ })
endfunction

function! s:parse_project_namespaces_response(resp) abort
  if !has_key(a:resp, 'value')
    return []
  endif
  return split(substitute(a:resp['value'], '[()]', '', 'g'), ' \+')
endfunction

function! iced#nrepl#cider#project_namespaces(callback) abort
  let code = '(do (require ''orchard.namespace)'
      \ . '(sort (orchard.namespace/project-namespaces)))'
  call iced#nrepl#eval(code, {resp -> a:callback(s:parse_project_namespaces_response(resp))})
endfunction

function! iced#nrepl#cider#macroexpand_1(code, callback) abort
  if !iced#nrepl#is_connected() | echom iced#message#get('not_connected') | return | endif

  call iced#nrepl#send({
      \ 'id': iced#nrepl#eval#id(),
      \ 'op': 'macroexpand',
      \ 'ns': iced#nrepl#ns#name(),
      \ 'code': a:code,
      \ 'session': iced#nrepl#current_session(),
      \ 'expander': 'macroexpand-1',
      \ 'callback': a:callback,
      \ })
endfunction

function! iced#nrepl#cider#macroexpand_all(code, callback) abort
  if !iced#nrepl#is_connected() | echom iced#message#get('not_connected') | return | endif

  call iced#nrepl#send({
      \ 'id': iced#nrepl#eval#id(),
      \ 'op': 'macroexpand',
      \ 'ns': iced#nrepl#ns#name(),
      \ 'code': a:code,
      \ 'session': iced#nrepl#current_session(),
      \ 'expander': 'macroexpand-all',
      \ 'callback': a:callback,
      \ })
endfunction

function! iced#nrepl#cider#pprint_eval(code, callback) abort
  if !iced#nrepl#is_connected() | echom iced#message#get('not_connected') | return | endif

  call iced#nrepl#send({
      \ 'id': iced#nrepl#eval#id(),
      \ 'op': 'eval',
      \ 'code': a:code,
      \ 'pprint': 'true',
      \ 'session': iced#nrepl#current_session(),
      \ 'callback': a:callback,
      \ })
endfunction

call iced#nrepl#register_handler('info')
call iced#nrepl#register_handler('ns-path')
call iced#nrepl#register_handler('format-code')
call iced#nrepl#register_handler('test', funcref('s:test_handler'))
call iced#nrepl#register_handler('retest', funcref('s:test_handler'))
call iced#nrepl#register_handler('test-all', funcref('s:test_handler'))
call iced#nrepl#register_handler('undef')
call iced#nrepl#register_handler('macroexpand')

let &cpo = s:save_cpo
unlet s:save_cpo
