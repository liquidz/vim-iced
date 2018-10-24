let s:save_cpo = &cpo
set cpo&vim

let s:ch = {
    \ 'env': 'neovim',
    \ 'is_connected': v:false,
    \ }

function! s:handle(ch_id) abort
  return {'ch_id': a:ch_id}
endfunction

function! s:ch_id(handle) abort
  return a:handle['ch_id']
endfunction

function! s:data_rely(data) abort
  if type(a:data) == type([])
    return join(a:data, "\n")
  endif
  return a:data
endfunction

function! s:ch.open(address, options) abort
  let opts = {}
  if has_key(a:options, 'callback')
    let opts['on_data'] = {ch_id, data, _ ->
          \ a:options.callback(s:handle(ch_id), s:data_rely(data))}
  endif
  
  let id = sockconnect('tcp', a:address, opts)
  let handle = s:handle(id)
  let handle['address'] = a:address
  let self['is_connected'] = v:true
  return handle
endfunction

function! s:ch.close(handle) abort
  return chanclose(s:ch_id(a:handle))
endfunction

function! s:ch.status(handle) abort
  return (self['is_connected'] ? 'open' : 'closed')
endfunction

function! s:ch.sendraw(handle, string) abort
  let id = s:ch_id(a:handle)
  let ret = chansend(id, a:string)
  if ret == 0
    let self['is_connected'] = v:false
  endif
  return ret
endfunction

function! iced#dicon#channel#neovim#build() abort
  return s:ch
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
