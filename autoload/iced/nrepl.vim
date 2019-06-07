let s:save_cpo = &cpo
set cpo&vim

" NOTE: `current_session_key` must be 'clj' or 'cljs'
function! s:initialize_nrepl() abort
  return {
      \ 'port': '',
      \ 'channel': v:false,
      \ 'current_session_key': '',
      \ 'sessions': {
      \   'repl': '',
      \   'clj':  '',
      \   'cljs': '',
      \   'cljs_repl': '',
      \   },
      \ }
endfunction
let s:nrepl = s:initialize_nrepl()
let s:handlers = {}

let s:messages = {}
let s:response_buffer = ''

let s:printer_dict = {
      \ 'default': 'cider.nrepl.pprint/pprint',
      \ }

let s:V = vital#iced#new()
let s:L = s:V.import('Data.List')

let g:iced#nrepl#host = get(g:, 'iced#nrepl#host', '127.0.0.1')
let g:iced#nrepl#buffer_size = get(g:, 'iced#nrepl#buffer_size', 1048576)
let g:iced#nrepl#printer = get(g:, 'iced#nrepl#printer', 'default')

let s:id_counter = 1
function! iced#nrepl#id() abort
  let res = s:id_counter
  let s:id_counter = (res < 100) ? res + 1 : 1
  return res
endfunction

function! s:set_message(id, msg) abort
  let s:messages[a:id] = a:msg
endfunction

function! s:clear_messages() abort
  let s:messages = {}
endfunction

" SESSIONS {{{
function! iced#nrepl#set_session(k, v) abort
  if a:k =~# '\(cljs\?\|repl\|cljs_repl\)'
    let s:nrepl['sessions'][a:k] = a:v
  else
    throw printf('Invalid session-key to set: %s', a:k)
  endif
endfunction

function! iced#nrepl#get_session(k) abort
  if a:k =~# '\(cljs\?\|repl\|cljs_repl\)'
    return s:nrepl['sessions'][a:k]
  else
    throw printf('Invalid session-key to get: %s', a:k)
  endif
endfunction

function! iced#nrepl#current_session_key() abort
  return get(s:nrepl, 'current_session_key', '')
endfunction

function! iced#nrepl#current_session() abort
  let k = iced#nrepl#current_session_key()
  return get(s:nrepl['sessions'], k, '')
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

function! iced#nrepl#cljs_session() abort
  return s:nrepl['sessions']['cljs']
endfunction

function! iced#nrepl#cljs_repl_session() abort
  return s:nrepl['sessions']['cljs_repl']
endfunction

function! iced#nrepl#repl_session() abort
  return s:nrepl['sessions']['repl']
endfunction

function! iced#nrepl#check_session_validity(...) abort
  let ext = expand('%:e')
  let sess_key = iced#nrepl#current_session_key()
  let is_verbose = get(a:, 1, v:true)

  if !empty(ext) && ext !=# 'cljc' && sess_key !=# ext
    if is_verbose
      call iced#message#error('invalid_session', ext)
    endif
    return v:false
  endif

  return v:true
endfunction
" }}}

" HANDLER {{{
function! s:get_message_id(x) abort
  if type(a:x) != v:t_dict
    return -1
  endif
  return get(a:x, 'id', get(a:x, 'original-id', -1))
endfunction

function! s:get_message_ids(x) abort
  let x = copy(a:x)
  call map(x, {_, v -> s:get_message_id(v)})
  return s:L.uniq(x)
endfunction

function! iced#nrepl#merge_response_handler(resp, last_result) abort
  let result = empty(a:last_result) ? {'value': ''} : a:last_result
  for resp in iced#util#ensure_array(a:resp)
    for k in keys(resp)
      if k ==# 'value'
        let result[k] = result[k] . resp[k]
      else
        let result[k] = resp[k]
      endif
    endfor
  endfor

  return result
endfunction

function! iced#nrepl#extend_responses_handler(resp, last_result) abort
  let responses = empty(a:last_result) ? [] : a:last_result
  call extend(responses, iced#util#ensure_array(a:resp))
  return responses
endfunction

function! s:default_handler(resp, _) abort
  return a:resp
endfunction

function! iced#nrepl#register_handler(op, handler) abort
  if type(a:handler) != v:t_func
    throw 'handler must be funcref'
  endif
  let s:handlers[a:op] = a:handler
endfunction
" }}}

" DISPATCHER {{{
function! s:dispatcher(ch, resp) abort
  let text = printf('%s%s', s:response_buffer, a:resp)
  call iced#util#debug('<<<', text)

  try
    let original_resp = iced#di#get('bencode').decode(text)
  catch /Failed to parse bencode/
    let s:response_buffer = (len(text) > g:iced#nrepl#buffer_size) ? '' : text
    return
  endtry

  let s:response_buffer = ''
  let responses = iced#util#ensure_array(original_resp)
  let ids = s:get_message_ids(responses)
  let original_resp_type = type(original_resp)

  for resp in responses
    if type(resp) != v:t_dict
      break
    endif

    if !get(get(s:messages, s:get_message_id(resp), {}), 'verbose', v:true)
      continue
    endif

    if has_key(resp, 'out')
      call iced#buffer#stdout#append(resp['out'])
    endif
    if has_key(resp, 'err')
      call iced#buffer#stdout#append(resp['err'])
    endif
    if has_key(resp, 'pprint-out')
      call iced#buffer#stdout#append(resp['pprint-out'])
    endif
  endfor

  for id in ids
    if has_key(s:messages, id)
      let resp = filter(copy(responses), {_, r -> s:get_message_id(r) == id})
      if original_resp_type == v:t_dict && len(resp) == 1
        let resp = resp[0]
      endif

      let last_handler_result = get(s:messages[id], 'handler_result', '')
      let Handler = get(s:handlers, s:messages[id]['op'], funcref('s:default_handler'))
      if type(Handler) == v:t_func
        let s:messages[id]['handler_result'] = Handler(resp, last_handler_result)
      endif

      if iced#util#has_status(resp, 'done')
        let Callback = get(s:messages[id], 'callback')
        let handler_result = get(s:messages[id], 'handler_result')
        unlet s:messages[id]
        call iced#nrepl#debug#quit()

        if !empty(handler_result) && type(Callback) == v:t_func
          call Callback(handler_result)
        endif
      endif
    endif

    if iced#util#has_status(resp, 'need-debug-input')
      if !iced#buffer#stdout#is_visible() && !iced#di#get('popup').is_supported()
        call iced#buffer#stdout#open()
      endif
      call iced#nrepl#debug#start(resp)
    endif
  endfor
endfunction
" }}}

" SEND {{{
function! iced#nrepl#auto_connect() abort
  call iced#message#echom('auto_connect')
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

  call iced#util#debug('>>>', a:data)

  let data = copy(a:data)
  let id = s:get_message_id(data)

  let message = {'op': data['op']}

  if has_key(data, 'verbose')
    let message['verbose'] = data['verbose']
    unlet data['verbose']
  endif

  if has_key(data, 'callback')
    if type(data['callback']) == v:t_func
      let message['callback'] = data['callback']
    endif
    unlet data['callback']
  endif

  if has_key(data, 'does_not_capture_id')
    unlet data['does_not_capture_id']
  else
    call s:set_message(id, message)
  endif

  call iced#di#get('channel').sendraw(
        \ s:nrepl['channel'],
        \ iced#di#get('bencode').encode(data))
endfunction

function! iced#nrepl#is_op_running(op) abort " {{{
  for id in keys(s:messages)
    if s:messages[id]['op'] ==# a:op
      return v:true
    endif
  endfor
  return v:false
endfunction " }}}
" }}}

" CONNECT {{{
function! s:warm_up() abort
  " FIXME init-debugger does not return response immediately
  call iced#nrepl#op#cider#debug#init()
  sleep 100m
  call iced#nrepl#op#cider#debug#init()

  if iced#nrepl#check_session_validity(v:false)
    call iced#nrepl#ns#in()
  endif
  call iced#format#set_indentexpr()
endfunction

function! s:status(ch) abort
  try
    return iced#di#get('channel').status(a:ch)
  catch
    return 'fail'
  endtry
endfunction

function! s:connected(resp, initial_session) abort
  if has_key(a:resp, 'new-session')
    let session = a:resp['new-session']
    let repl_session_key = (a:initial_session ==# 'cljs') ? 'cljs_repl' : 'repl'
    call iced#nrepl#set_session(repl_session_key, session)

    let new_session = iced#nrepl#sync#clone(session)
    call iced#nrepl#set_session(a:initial_session, new_session)
    call iced#nrepl#change_current_session(a:initial_session)

    silent call s:warm_up()

    call iced#nrepl#auto#enable_bufenter(v:true)
    call iced#message#info('connected')
  endif
endfunction

function! iced#nrepl#connect(port, ...) abort
  " required by iced#buffer
  if !&hidden
    return iced#message#error('no_set_hidden')
  endif

  if iced#nrepl#is_connected()
    call iced#message#info('already_connected')
    return v:true
  endif

  " NOTE: Initialize buffers here to avoid firing `bufenter` autocmd
  "       after connection established
  call iced#buffer#stdout#init()
  call iced#buffer#document#init()
  call iced#buffer#error#init()

  if empty(a:port)
    return iced#nrepl#connect#auto()
  endif

  if !iced#nrepl#is_connected()
    let address = printf('%s:%d', g:iced#nrepl#host, a:port)
    let s:nrepl['port'] = a:port
    let s:nrepl['channel'] = iced#di#get('channel').open(address, {
        \ 'mode': 'raw',
        \ 'callback': funcref('s:dispatcher'),
        \ 'drop': 'never',
        \ })

    if !iced#nrepl#is_connected()
      let s:nrepl['channel'] = v:false
      call iced#message#error('connect_error')
      return v:false
    endif
  endif

  let initial_session = get(a:, 1, 'clj')
  call iced#nrepl#send({'op': 'clone', 'callback': {resp -> s:connected(resp, initial_session)}})
  return v:true
endfunction

function! iced#nrepl#is_connected() abort " {{{
  return (s:status(s:nrepl['channel']) ==# 'open')
endfunction " }}}

function! iced#nrepl#disconnect() abort " {{{
  if !iced#nrepl#is_connected() | return | endif

  for id in iced#nrepl#sync#session_list()
    call iced#nrepl#sync#send({'op': 'interrupt', 'session': id})
    call iced#nrepl#sync#close(id)
  endfor
  call iced#di#get('channel').close(s:nrepl['channel'])
  let s:nrepl = s:initialize_nrepl()
  call iced#cache#clear()
  call iced#nrepl#cljs#reset()
  call iced#message#info('disconnected')
endfunction " }}}

function! iced#nrepl#reconnect() abort " {{{
  if !iced#nrepl#is_connected()
    return iced#nrepl#connect#auto()
  endif

  let port = s:nrepl['port']
  call iced#nrepl#disconnect()
  sleep 500m
  call iced#nrepl#connect(port)
endfunction " }}}
" }}}

" EVAL {{{
function! iced#nrepl#is_evaluating() abort
  return !empty(s:messages)
        \ && (len(s:messages) != 1 || s:messages[keys(s:messages)[0]]['op'] !=# 'iced-lint-file')
endfunction

function! iced#nrepl#eval(code, ...) abort
  if !iced#nrepl#is_connected() && !iced#nrepl#auto_connect()
    return
  endif

  let Callback = get(a:, 1, '')
  let option = get(a:, 2, {})
  let session_key  = get(option, 'session', iced#nrepl#current_session_key())
  let session = get(s:nrepl['sessions'], session_key, iced#nrepl#current_session())
  let pos = getcurpos()
  let msg = {
        \ 'id': get(option, 'id', iced#nrepl#id()),
        \ 'op': 'eval',
        \ 'code': a:code,
        \ 'session': session,
        \ 'file': get(option, 'file', expand('%:p')),
        \ 'line': get(option, 'line', pos[1]),
        \ 'column': get(option, 'column', pos[2]),
        \ 'nrepl.middleware.print/stream?': 1,
        \ 'callback': Callback,
        \ }

  if has_key(option, 'use-printer?')
    let msg['nrepl.middleware.print/print'] = get(s:printer_dict, g:iced#nrepl#printer, s:printer_dict['default'])
  endif

  call iced#nrepl#send(msg)
endfunction

function! iced#nrepl#load_file(callback) abort " {{{
  if !iced#nrepl#is_connected() && !iced#nrepl#auto_connect()
    return
  endif

  call iced#nrepl#send({
      \ 'id': iced#nrepl#id(),
      \ 'op': 'load-file',
      \ 'session': iced#nrepl#current_session(),
      \ 'file': join(getline(1, '$'), "\n"),
      \ 'file-name': expand('%'),
      \ 'file-path': expand('%:p'),
      \ 'callback': a:callback,
      \ })
endfunction " }}}
" }}}

" INTERRUPT {{{
function! s:interrupted() abort
  call s:clear_messages()
  call iced#message#info('interrupted')
endfunction

function! iced#nrepl#interrupt(...) abort
  if ! iced#nrepl#is_connected() | return iced#message#warning('not_connected') | endif
  let session = get(a:, 1, iced#nrepl#current_session())
  " NOTE: ignore reading error
  let s:response_buffer = ''
  call iced#nrepl#send({
      \ 'op': 'interrupt',
      \ 'session': session,
      \ 'callback': {_ -> s:interrupted()},
      \ })
endfunction
" }}}

call iced#nrepl#register_handler('eval', funcref('iced#nrepl#merge_response_handler'))
call iced#nrepl#register_handler('load-file', funcref('iced#nrepl#merge_response_handler'))

let &cpo = s:save_cpo
unlet s:save_cpo
" vim:fdm=marker:fdl=0
