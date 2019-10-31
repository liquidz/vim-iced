let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:extract_source(resp) abort
  let path = get(a:resp, 'file', '')
  if empty(path) | return '' | endif

  let code = ''
  let reg_save = @@
  try
    call iced#buffer#temporary#begin()
    call iced#system#get('ex_cmd').silent_exe(printf(':read %s', path))
    call cursor(a:resp['line']+1, get(a:resp, 'column', 0))
    silent normal! vaby
    let code = @@
  finally
    let @@ = reg_save
    call iced#buffer#temporary#end()
  endtry

  return code
endfunction

function! s:fetch_source(symbol) abort
  return iced#promise#call('iced#nrepl#var#get', [a:symbol])
        \.then(funcref('s:extract_source'))
endfunction

function! iced#nrepl#source#show(symbol) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let symbol = empty(a:symbol) ? iced#nrepl#var#cword() : a:symbol
  call s:fetch_source(symbol)
       \.then({code -> empty(code)
       \       ? iced#message#error('not_found')
       \       : iced#buffer#document#open(code, 'clojure')})
endfunction

function! s:try_to_fallback(symbol, err) abort
  if type(a:err) != v:t_dict
        \ || !has_key(a:err, 'exception')
    return iced#message#error('unexpected_error', string(a:err))
  endif

  let ex = a:err['exception']
  if stridx(ex, 'vim-iced: too long texts to show in popup') == 0
    call iced#nrepl#source#show(a:symbol)
  endif

  return iced#message#warning('popup_error', string(ex))
endfunction

function! iced#nrepl#source#popup_show(symbol) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  if !iced#system#get('popup').is_supported()
    return iced#nrepl#source#show(a:symbol)
  endif

  let symbol = empty(a:symbol) ? iced#nrepl#var#cword() : a:symbol
  call s:fetch_source(symbol)
       \.then({code -> empty(code)
       \       ? iced#message#error('not_found')
       \       : iced#system#get('popup').open(
       \           split(code, '\r\?\n'), {
       \           'line': 'near-cursor',
       \           'col': col('.'),
       \           'filetype': 'clojure',
       \           'border': [],
       \           'borderhighlight': ['Comment'],
       \           'auto_close': v:false,
       \           'moved': 'any',
       \           })})
       \.catch({err -> s:try_to_fallback(a:symbol, err)})
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
