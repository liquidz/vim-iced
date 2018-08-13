let s:save_cpo = &cpo
set cpo&vim

" NOTE: `current_session_key` must be 'clj' or 'cljs'
let s:nrepl = {
    \ 'channel': v:false,
    \ 'current_session_key': v:none,
    \ 'sessions': {
    \   'repl': v:none,
    \   'clj':  v:none,
    \   'cljs': v:none,
    \   },
    \ 'handler': {},
    \ }

let s:messages = {}
let s:response_buffer = ''

let g:iced#nrepl#host = get(g:, 'iced#nrepl#host', '127.0.0.1')
let g:iced#nrepl#buffer_size = get(g:, 'iced#nrepl#buffer_size', 1048576)

"" ---------
"" =SESSIONS
"" ---------

function! iced#nrepl#set_session(k, v) abort
  if a:k =~# '\(cljs\?\|repl\)'
    let s:nrepl['sessions'][a:k] = a:v
  else
    throw printf('Invalid session-key to set: %s', a:k)
  endif
endfunction

function! iced#nrepl#current_session_key() abort
  return get(s:nrepl, 'current_session_key', v:none)
endfunction

function! iced#nrepl#current_session() abort
  let k = iced#nrepl#current_session_key()
  return get(s:nrepl['sessions'], k, v:none)
endfunction


function! iced#nrepl#change_current_session(k) abort
  if a:k =~# 'cljs\?'
    let s:nrepl['current_session_key'] = a:k
  else
    throw printf('Invalid session-key to change: %s', a:k)
  endif
endfunction

function! iced#nrepl#clj_session() abort
  return s:nrepl['sessions']['clj']
endfunction

function! iced#nrepl#repl_session() abort
  return s:nrepl['sessions']['repl']
endfunction

"" --------
"" =HANDLER
"" --------

function! s:get_message_id(x) abort
  let x = a:x
  if type(x) == type([])
    let x = x[0]
  endif
  if type(x) == type({})
    return get(x, 'id', -1)
  else
    return -1
  endif
endfunction

function! s:is_done(resp) abort
  for resp in iced#util#ensure_array(a:resp)
    let status = get(resp, 'status', [v:none])[0]
    if status ==# 'done'
      return v:true
    endif
  endfor
  return v:false
endfunction

function! s:merge_response_handler(resp) abort
  let id = s:get_message_id(a:resp)
  let result = get(s:messages[id], 'result', {})

  for resp in iced#util#ensure_array(a:resp)
    for k in keys(resp)
      let result[k] = resp[k]
    endfor
  endfor

  let s:messages[id]['result'] = result
  return result
endfunction

function! s:identity_handler(resp) abort
  return a:resp
endfunction

function! iced#nrepl#register_handler(op, ...) abort
  let Handler = get(a:, 1, funcref('s:identity_handler'))

  if !iced#util#is_function(Handler)
    throw 'handler must be funcref'
  endif
  let s:nrepl['handler'][a:op] = Handler
endfunction

"" -----------
"" =DISPATCHER
"" -----------

function! s:dispatcher(ch, resp) abort
  let text = printf('%s%s', s:response_buffer, a:resp)
  try
    let resp = iced#nrepl#bencode#decode(text)
    let s:response_buffer = ''
    let id = s:get_message_id(resp)

    for rsp in iced#util#ensure_array(resp)
      if type(rsp) == type({})
        for k in ['out', 'err']
          if has_key(rsp, k)
            call iced#buffer#append(rsp[k])
          endif
        endfor
      endif
    endfor

    if has_key(s:messages, id)
      let handler_result = v:none
      let Handler = get(s:nrepl['handler'], s:messages[id]['op'], v:none)
      if iced#util#is_function(Handler)
        let handler_result = Handler(resp)
      endif

      if s:is_done(resp)
        let Callback = get(s:messages[id], 'callback')
        unlet s:messages[id]

        if !empty(handler_result) && iced#util#is_function(Callback)
          call Callback(handler_result)
        endif
      endif
    endif

  catch /Failed to parse bencode/
    let s:response_buffer = (len(text) > g:iced#nrepl#buffer_size) ? '' : text
  endtry
endfunction

"" -----
"" =SEND
"" -----

function! s:auto_connect() abort
  echom iced#message#get('auto_connect')
  if ! iced#nrepl#connect#auto()
    call iced#message#error('try_connect')
    return v:false
  endif

  if !iced#util#wait({-> empty(s:nrepl['current_session_key'])}, 500)
    call iced#message#error('timeout')
    return v:false
  endif
  return v:true
endfunction

function! iced#nrepl#send(data) abort
  if !empty(s:response_buffer)
    call iced#message#warning('reading')
    return
  endif

  let data = copy(a:data)
  let id = s:get_message_id(data)

  let message = {'op': data['op']}

  if has_key(data, 'callback')
    if iced#util#is_function(data['callback'])
      let message['callback'] = data['callback']
    endif
    unlet data['callback']
  endif

  let s:messages[id] = message

  call ch_sendraw(s:nrepl['channel'], iced#nrepl#bencode#encode(data))
endfunction

"" --------
"" =CONNECT
"" --------

function! s:status(ch) abort
  try
    return ch_status(a:ch)
  catch
    return 'fail'
  endtry
endfunction

function! s:connected(resp) abort
  if has_key(a:resp, 'new-session')
    let session = a:resp['new-session']
    call iced#nrepl#set_session('repl', session)

    let new_session = iced#nrepl#sync#clone(session)
    call iced#nrepl#set_session('clj', new_session)
    call iced#nrepl#change_current_session('clj')

    call iced#buffer#init()
    echom iced#message#get('connected')
  endif
endfunction

function! iced#nrepl#connect(port) abort
  if empty(a:port)
    return iced#nrepl#connect#auto()
  endif

  if ! iced#nrepl#is_connected()
    let address = printf('%s:%d', g:iced#nrepl#host, a:port)
    let s:nrepl['channel'] = ch_open(address, {
        \ 'mode': 'raw',
        \ 'callback': funcref('s:dispatcher'),
        \ 'drop': 'never',
        \ })

    if !iced#nrepl#is_connected()
      let s:nrepl['channel'] = v:false
      call iced#message#error('connect_error')
      return
    endif
  endif

  call iced#nrepl#send({'op': 'clone', 'callback': funcref('s:connected')})
endfunction

function! iced#nrepl#is_connected() abort
  return (s:status(s:nrepl['channel']) ==# 'open')
endfunction

function! iced#nrepl#disconnect() abort
  if !iced#nrepl#is_connected()
    return
  endif

  for id in iced#nrepl#sync#session_list()
    call iced#nrepl#sync#close(id)
  endfor
  call ch_close(s:nrepl['channel'])
endfunction

function! s:interrupted() abort
  let s:messages = {}
  echom iced#message#get('interrupted')
endfunction

function! iced#nrepl#interrupt(...) abort
  if ! iced#nrepl#is_connected()
    call iced#message#warning('not_connected')
    return
  endif
  let session = get(a:, 1, iced#nrepl#current_session())
  call iced#nrepl#send({
      \ 'op': 'interrupt',
      \ 'session': session,
      \ 'callback': {_ -> s:interrupted()},
      \ })
endfunction

"" -----
"" =EVAL
"" -----

function! iced#nrepl#is_evaluating() abort
  return !empty(s:messages)
endfunction

function! iced#nrepl#eval(code, ...) abort
  if !iced#nrepl#is_connected() && !s:auto_connect()
    return
  endif

  let Callback = get(a:, 1, v:none)
  let option = get(a:, 2, {})
  let session_key  = get(option, 'session', 'clj')
  let session = get(s:nrepl['sessions'], session_key, iced#nrepl#current_session())

  let pos = getcurpos()
  call iced#nrepl#send({
      \ 'id': iced#nrepl#eval#id(),
      \ 'op': 'eval',
      \ 'code': a:code,
      \ 'session': session,
      \ 'file': expand('%:p'),
      \ 'line': get(option, 'line', pos[1]),
      \ 'column': get(option, 'column', pos[2]),
      \ 'callback': Callback,
      \ })
endfunction

function! iced#nrepl#load_file(callback) abort
  if !iced#nrepl#is_connected() && !s:auto_connect()
    return
  endif

  call iced#nrepl#send({
      \ 'id': iced#nrepl#eval#id(),
      \ 'op': 'load-file',
      \ 'session': iced#nrepl#current_session(),
      \ 'file': join(getline(1, '$'), "\n"),
      \ 'file-name': expand('%'),
      \ 'file-path': expand('%:p'),
      \ 'callback': a:callback,
      \ })
endfunction

call iced#nrepl#register_handler('clone')
call iced#nrepl#register_handler('interrupt')
call iced#nrepl#register_handler('eval', funcref('s:merge_response_handler'))
call iced#nrepl#register_handler('load-file', funcref('s:merge_response_handler'))

let &cpo = s:save_cpo
unlet s:save_cpo
