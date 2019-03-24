let s:save_cpo = &cpo
set cpo&vim

let g:iced#nrepl#host = get(g:, 'iced#nrepl#host', '127.0.0.1')
let g:iced#nrepl#buffer_size = get(g:, 'iced#nrepl#buffer_size', 1048576)

let s:nrepl = {
      \ 'state': {'bencode': {}, 'channel': []},
      \ 'port': '',
      \ 'channel': v:false,
      \ 'response_buffer': '',
      \ 'callback': '',
      \ }

function! s:detect_port_from_nrepl_port_file() abort
  let path = findfile('.nrepl-port', '.;')
  return (empty(path)
        \ ? v:false
        \ : str2nr(readfile(path)[0]))
endfunction

function! s:detect_shadow_cljs_nrepl_port() abort
  let dot_shadow_cljs = finddir('.shadow-cljs', '.;')
  if empty(dot_shadow_cljs) | return v:false | endif

  let path = findfile('nrepl.port', dot_shadow_cljs)
  return (empty(path)
        \ ? v:false
        \ : str2nr(readfile(path)[0]))
endfunction

function! s:detect_port() abort
  let port = s:detect_shadow_cljs_nrepl_port()

  if ! port
    let port = s:detect_port_from_nrepl_port_file()
  endif

  return port
endfunction

function! s:nrepl.is_connected() abort
  try
    return (self.state.channel.status(self.channel) ==# 'open')
  catch
    return 0
  endtry
endfunction

function! s:nrepl.send(message) abort
  if !empty(self.response_buffer)
    call iced#message#warning('reading')
    return
  endif

  call iced#util#debug('>>>', a:message)

  call self.state.channel.sendraw(
        \ self.channel,
        \ self.state.bencode.encode(a:message))
endfunction

function! s:nrepl.receive(resp) abort
  let text = printf('%s%s', self.response_buffer, a:resp)
  call iced#util#debug('<<<', text)

  try
    let decoded_resp = self.state.bencode.decode(text)
  catch /Failed to parse bencode/
    let self['response_buffer'] = (len(text) > g:iced#nrepl#buffer_size) ? '' : text
    return
  endtry

  let self.response_buffer = ''

  if !empty(self.callback)
    call self.callback(decoded_resp)
  endif
endfunction

function! s:nrepl.clear() abort
  let self['response_buffer'] = ''
endfunction

function! iced#state#nrepl#start(params) abort
  let nrepl = deepcopy(s:nrepl)

  let nrepl['state']['bencode'] = a:params.require.bencode
  let nrepl['state']['channel'] = a:params.require.channel

  let nrepl['port'] = empty(get(a:params, 'port'))
        \ ? s:detect_port()
        \ : a:params['port']

  if has_key(a:params, 'callback') && type(a:params['callback']) == v:t_func
    let nrepl['callback'] = a:params['callback']
  endif

  if empty(nrepl['port'])
    call iced#message#error('no_port_file')
    return v:false
  endif

  let address = printf('%s:%d', g:iced#nrepl#host, nrepl['port'])
  let nrepl['channel'] = nrepl.state.channel.open(address, {
        \ 'mode': 'raw',
        \ 'callback': {_, resp -> nrepl.receive(resp)},
        \ 'drop': 'never'})

  if !nrepl.is_connected()
    let nrepl['channel'] = v:false
    call iced#message#error('connect_error')
    return v:false
  endif

  return nrepl
endfunction

function! iced#state#nrepl#stop(nrepl) abort
  call a:nrepl.state.channel.close(a:nrepl.channel)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
