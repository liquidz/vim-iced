let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:initialize_socket_repl() abort
  return {
        \ 'port': '',
        \ 'channel': v:false,
        \ 'prompt': '\([A-Za-z0-9\-]\+\.\)\?[A-Za-z0-9\-]\+=> ',
        \ 'ignore_prompt': '#_=>\s\+',
        \ 'handler': '',
        \ 'repl_type': 'unknown',
        \ }
endfunction
let s:socket_repl = s:initialize_socket_repl()
let s:response_buffer = ''

let g:iced#socket_repl#host = get(g:, 'iced#socket_repl#host', '127.0.0.1')
let g:iced#socket_repl#buffer_size = get(g:, 'iced#socket_repl#buffer_size', 1048576)

function! s:default_callback(resp) abort
  let out = get(a:resp, 'out')
  let value = get(a:resp, 'value', '')

  if !empty(out)
    call iced#buffer#stdout#append(out)
  endif

  if !empty(value)
    echo iced#util#shorten(value)
    call iced#system#get('virtual_text').set(
          \ printf('=> %s', value),
          \ {'highlight': 'Comment', 'auto_clear': v:true})
  endif
endfunction

function! s:connecting_callback(resp) abort
  let out = tolower(get(a:resp, 'out', ''))
  for kw in ['babashka', 'joker', 'lumo', 'cljs.user']
    if stridx(out, kw) != -1
      let s:socket_repl['repl_type'] = kw
      break
    endif
  endfor

  return s:default_callback(a:resp)
endfunction

let s:callback = funcref('s:default_callback')

" DISPATCHER {{{

function! s:dispatcher(ch, resp) abort
  let resp = join(iced#util#ensure_array(a:resp), ' ,,, ')
  let text = printf('%s%s', s:response_buffer, resp)
  call iced#util#debug('<<<', text)

  let s:response_buffer = (len(text) > g:iced#socket_repl#buffer_size) ? '' : text
  let text = substitute(text, s:socket_repl['ignore_prompt'], '', 'g')

  let idx = match(text, s:socket_repl['prompt'])
  if idx == -1
    return
  endif

  let s:response_buffer = ''

  let Handler = get(s:socket_repl, 'handler', '')
  if type(Handler) == v:t_func
    call Handler(text, s:callback)
  else
    let value = trim(strpart(text, 0, idx))
    let idx = strridx(value, "\n")
    if idx != -1
      let value = strpart(value, idx + 1)
    endif
    call s:callback({'out': text, 'value': value})
  endif
endfunction " }}}

" SEND {{{
function! iced#socket_repl#send(data) abort
  call iced#util#debug('>>>', a:data)
  call iced#system#get('channel').sendraw(
        \ s:socket_repl['channel'],
        \ printf("%s\n", a:data))
endfunction " }}}

" CONNECT {{{
function! s:status(ch) abort
  try
    return iced#system#get('channel').status(a:ch)
  catch
    return 'fail'
  endtry
endfunction

function! iced#socket_repl#connect(port, ...) abort
  let opt = get(a:, 1, {})
  let verbose = get(opt, 'verbose', v:true)

  if iced#socket_repl#is_connected()
    if verbose
      call iced#message#info('already_connected')
    endif
    return v:true
  else
    " NOTE: Initialize buffers here to avoid firing `bufenter` autocmd
    "       after connection established
    silent call iced#buffer#stdout#init()

    " to detect repl type
    let s:callback = funcref('s:connecting_callback')

    let address = printf('%s:%d', g:iced#socket_repl#host, a:port)
    let s:socket_repl['port'] = a:port
    try
      let s:socket_repl['channel'] = iced#system#get('channel').open(address, {
            \ 'mode': 'raw',
            \ 'callback': funcref('s:dispatcher'),
            \ 'drop': 'never',
            \ })
    catch
      if verbose
        call iced#message#error('connect_error')
      endif
      return v:false
    endtry

    if has_key(opt, 'prompt') && !empty(opt['prompt'])
      let s:socket_repl['prompt'] = opt['prompt']
    endif
    let s:socket_repl['handler'] = get(opt, 'handler', '')

    if !iced#socket_repl#is_connected()
      let s:socket_repl['channel'] = v:false
      if verbose
        call iced#message#error('connect_error')
      endif
      return v:false
    endif
  endif

  " NOTE: socket-repl connection in vim-iced does not support `bufenter` autocmd currently.
  " call iced#nrepl#auto#enable_bufenter(v:true)

  if verbose
    call iced#message#info('connected')
  endif
  call iced#hook#run('connected', {})
  return v:true
endfunction

function! iced#socket_repl#is_connected() abort
  return (s:status(s:socket_repl['channel']) ==# 'open')
endfunction

function! iced#socket_repl#disconnect() abort
  if !iced#socket_repl#is_connected() | return | endif

  " NOTE: 'timer' feature seems not to work on VimLeave.
  "       To receive response correctly, replace 'future' component not to use 'timer'.
  call iced#system#set_component('future', {'start': 'iced#component#future#instant#start'})

  call iced#system#get('channel').close(s:socket_repl['channel'])
  let s:socket_repl = s:initialize_socket_repl()
  call iced#cache#clear()
  call iced#message#info('disconnected')
  call iced#hook#run('disconnected', {})
endfunction " }}}

" EVAL {{{
function! iced#socket_repl#is_evaluating() abort
  return !empty(s:response_buffer)
endfunction

function! iced#socket_repl#eval(code, ...) abort
  if !iced#socket_repl#is_connected()
    return
  endif

  let opt = get(a:, 1, {})
  let s:callback = get(opt, 'callback', funcref('s:default_callback'))
  if type(s:callback) != v:t_func
    let s:callback = funcref('s:default_callback')
  endif

  call iced#socket_repl#send(a:code)
endfunction

function! iced#socket_repl#eval_outer_top_list(...) abort " {{{
  let ret = iced#paredit#get_current_top_list()
  let code = ret['code']
  if empty(code)
    return iced#message#error('finding_code_error')
  endif
  let code = iced#nrepl#eval#normalize_code(code)

  return iced#socket_repl#eval(code)
endfunction " }}}

function! iced#socket_repl#load_current_file() abort " {{{
  let whole_codes = join(getline(1, '$'), "\n")
  return iced#socket_repl#eval(whole_codes)
endfunction " }}}
" }}}

" STATUS {{{
function! iced#socket_repl#status() abort
  if !iced#socket_repl#is_connected()
    return 'not connected'
  else
    return 'connected'
  endif
endfunction " }}}

function! iced#socket_repl#trim_prompt(s) abort
  let idx = match(a:s, s:socket_repl['prompt'])
  if idx == -1 | return a:s | endif
  return trim(strpart(a:s, 0, idx))
endfunction

function! iced#socket_repl#repl_type() abort
  return s:socket_repl['repl_type']
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
" vim:fdm=marker:fdl=0
