let s:save_cpo = &cpoptions
set cpoptions&vim

let g:iced#debug#debugger = get(g:, 'iced#debug#debugger', 'default')

function! iced#nrepl#debug#start(resp) abort
  let Fn = function(printf('iced#nrepl#debug#%s#start', g:iced#debug#debugger))
  return Fn(a:resp)
endfunction

function! iced#nrepl#debug#quit() abort
  let Fn = function(printf('iced#nrepl#debug#%s#quit', g:iced#debug#debugger))
  return Fn()
endfunction

function! iced#nrepl#debug#browse_tapped(key_str) abort
  if empty(a:key_str)
    return s:show_tapped_list()
  endif

  return s:browse_tapped_data(a:key_str)
endfunction

function! s:show_tapped_list() abort
  return iced#promise#call('iced#nrepl#op#iced#list_tapped', [])
        \.then({resp -> has_key(resp, 'error') ? iced#promise#reject(resp['error']) : resp})
        \.then({resp -> map(get(resp, 'tapped', []), {i, v -> printf("%d: %s", i, get(v, 'value', ''))})})
        \.then({candidates -> empty(candidates)
        \                     ? iced#message#warning('not_found')
        \                     : iced#selector({'candidates': candidates,
        \                                      'accept': funcref('s:accept_tapped_value')})})
        \.catch({error -> iced#message#error_str(error)})
endfunction

function! s:accept_tapped_value(_, x) abort
  let i = stridx(a:x, ': ')
  if i < 0 | return | endif

  let k = a:x[:i-1]
  call iced#nrepl#debug#browse_tapped(k)
endfunction

function! s:browse_tapped_data(key_str) abort
  let keys = split(a:key_str, '\s\+')
  let keys = map(keys, {_, v ->
        \ (type(v) == v:t_string && match(v, '^\d\+$') == 0) ? str2nr(v) : v})

  let resp = iced#promise#sync('iced#nrepl#op#iced#browse_tapped', [keys])
  if has_key(resp, 'error') | return iced#message#error_str(resp['error']) | endif

  let value = get(resp, 'value', '')
  if empty(value) | return iced#message#warning('not_found') | endif
  call iced#buffer#document#open(value, 'clojure')

  " continue to browse the tapped value in command mode
  let cmd = printf(':IcedBrowseTapped %s ', a:key_str)
  let cmd = substitute(cmd, '\s\+', ' ', 'g')
  call iced#system#get('io').feedkeys(cmd, 'n')
  return iced#promise#resolve('')
endfunction


function! iced#nrepl#debug#complete_tapped(arg_lead, cmd_line, cursor_pos) abort
  if !iced#nrepl#is_connected() | return '' | endif

  let end = a:cursor_pos - (len(a:arg_lead) + 1)
  let cmd = trim(a:cmd_line[:end])

  let keys = split(cmd, '\s\+')[1:]
  let keys = map(keys, {_, v ->
        \ (type(v) == v:t_string && match(v, '^\d\+$') == 0) ? str2nr(v) : v})
  let resp = iced#promise#sync('iced#nrepl#op#iced#complete_tapped', [keys])
  return join(get(resp, 'complete', []), "\n")
endfunction

function! iced#nrepl#debug#clear_tapped() abort
  return iced#promise#call('iced#nrepl#op#iced#clear_tapped', [])
        \.then({resp -> has_key(resp, 'error')
        \               ? iced#promise#reject(resp['error'])
        \               : resp})
        \.then({_ -> iced#message#info('cleared')})
        \.catch({error -> iced#message#error_str(error)})
endfunction

function! s:toggled_warn_on_reflection(resp) abort
  if !has_key(a:resp, 'value')
    return iced#message#error('unexpected_error', string(a:resp))
  endif
  return iced#message#info('toggle_warn_on_reflection', a:resp['value'])
endfunction

function! iced#nrepl#debug#toggle_warn_on_reflection() abort
  let code = '(set! *warn-on-reflection* (not (true? *warn-on-reflection*)))'
  call iced#nrepl#eval(code, funcref('s:toggled_warn_on_reflection'))
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
