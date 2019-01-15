let s:save_cpo = &cpo
set cpo&vim

let s:ch = {
    \ 'env': 'neovim',
    \ 'is_connected': v:false,
    \ }

function! s:id_to_handler(ch_id) abort
  return {'ch_id': a:ch_id}
endfunction

function! s:ch_id(handler) abort
  return a:handler['ch_id']
endfunction

function! s:data_relay(data) abort
  if type(a:data) == v:t_list
    return join(a:data, "\n")
  endif
  return a:data
endfunction

function! s:ch.open(address, options) abort
  let opts = {}
  if has_key(a:options, 'callback')
    let opts['on_data'] = {ch_id, data, _ ->
          \ a:options.callback(s:id_to_handler(ch_id), s:data_relay(data))}
  endif

  let id = sockconnect('tcp', a:address, opts)
  let handler = s:id_to_handler(id)
  let handler['address'] = a:address
  let self['is_connected'] = v:true
  return handler
endfunction

function! s:ch.close(handler) abort
  let self['is_connected'] = v:false
  return chanclose(s:ch_id(a:handler))
endfunction

function! s:ch.status(handler) abort
  return (self['is_connected'] ? 'open' : 'closed')
endfunction

function! s:ch.sendraw(handler, string) abort
  let id = s:ch_id(a:handler)
  let ret = chansend(id, a:string)
  if ret == 0
    let self['is_connected'] = v:false
  endif
  return ret
endfunction

function! iced#di#channel#neovim#build() abort
  return s:ch
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
