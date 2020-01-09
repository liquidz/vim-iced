let s:save_cpo = &cpoptions
set cpoptions&vim

let g:iced#nrepl#source#fallback_to_source_when_no_definition
      \ = get(g:, 'iced#nrepl#source#fallback_to_source_when_no_definition', v:true)

" iced#nrepl#source#show {{{
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
        \.then({resp -> (empty(get(resp, 'file', '')))
        \               ? iced#promise#reject(iced#message#get('not_found'))
        \               : s:extract_source(resp)})
endfunction

function! iced#nrepl#source#show(symbol) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let symbol = empty(a:symbol) ? iced#nrepl#var#cword() : a:symbol
  call s:fetch_source(symbol)
       \.then({code -> empty(code)
       \       ? iced#message#error('not_found')
       \       : iced#buffer#document#open(code, 'clojure')})
endfunction
" }}}

" iced#nrepl#source#popup_show {{{
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
       \           'col': 'near-cursor',
       \           'filetype': 'clojure',
       \           'border': [],
       \           'borderhighlight': ['Comment'],
       \           'auto_close': v:false,
       \           'moved': 'any',
       \           })})
       \.catch({err -> s:try_to_fallback(a:symbol, err)})
endfunction
" }}}

" iced#nrepl#source#show_definition {{{
function! s:__format_definition_codes(resp) abort
  if type(a:resp) == v:t_string
    return a:resp
  endif

  let res = []
  let definition = get(a:resp, 'definition', {})

  call add(res, printf(';; file: %s', definition['file']))
  call add(res, printf(';; line: %d - %d', definition['line-beg'], definition['line-end']))
  call add(res, get(definition, 'definition', ''))
  return join(res, "\n")
endfunction

function! s:__extract_definition() abort
  let path = expand('%:p')
  let ns_name = iced#nrepl#ns#name()
  let sym = iced#nrepl#var#cword()
  let pos = getcurpos()

  return iced#promise#call('iced#nrepl#op#refactor#extract_definition', [path, ns_name, sym, pos[1], pos[2]])
       \.then({resp -> (has_key(resp, 'error')
       \               ? (g:iced#nrepl#source#fallback_to_source_when_no_definition)
       \                 ? s:fetch_source(sym)
       \                 : iced#promise#reject(resp['error'])
       \               : iced#promise#call(iced#system#get('edn').decode, [get(resp, 'definition', {})]))
       \               })
       \.then(funcref('s:__format_definition_codes'))
endfunction

function! iced#nrepl#source#show_definition() abort
  return s:__extract_definition()
        \.then({code -> empty(code)
        \       ? iced#promise#reject(iced#message#get('not_found'))
        \       : iced#buffer#document#open(code, 'clojure')})
        \.catch({err -> iced#message#error_str(err)})
endfunction
" }}}

" iced#nrepl#source#show_definition_popup {{{
function! iced#nrepl#source#show_definition_popup() abort
  if !iced#system#get('popup').is_supported()
    return iced#nrepl#source#show_definition()
  endif

  return s:__extract_definition()
        \.then({code -> iced#system#get('popup').open(
        \                 split(code, '\r\?\n'), {
        \                 'line': 'near-cursor',
        \                 'col': 'near-cursor',
        \                 'filetype': 'clojure',
        \                 'border': [],
        \                 'borderhighlight': ['Comment'],
        \                 'auto_close': v:false,
        \                 'moved': 'any',
        \                 })})
        \.catch({err -> iced#message#error_str(err)})
endfunction
" }}}

let &cpoptions = s:save_cpo
unlet s:save_cpo
" vim:fdm=marker:fdl=0
