let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('iced')
let s:M = s:V.import('Vim.Message')

let s:messages = {
    \ 'auto_connect':       'Auto connecting...',
    \ 'no_port_file':       '.nrepl-port is not found.',
    \ 'connect_error':      'Failed to connect.',
    \ 'not_connected':      'Not connected.',
    \ 'try_connect':        'Not connected. Try `:IcedConnect <port>`',
    \ 'connected':          'Connected.',
    \ 'interrupted':        'Interrupted.',
    \ 'reading':            'Still reading..',
    \ 'not_found':          'Not found.',
    \ 'required':           'Required.',
    \ 'timeout':            'Timed out.',
    \ 'invalid_cljs_env':   'Invalid CLJS environment.',
    \ 'started_cljs_repl':  'CLJS repl is started.',
    \ 'quitted_cljs_repl':  'CLJS repl is quitted.',
    \ 'no_document':        'Not documented.',
    \ 'too_deep_to_slurp':  'Too deep to slurp.',
    \ 'finding_code_error': 'Failed to find code.',
    \ 'no_ctrlp':           'CtrlP needed to select candidates is not installed.',
    \ 'no_candidates':      'No candidates.',
    \ 'alias_exists':       'Alias "%s" already exists.',
    \ }

function! iced#message#get(k) abort
  if has_key(s:messages, a:k)
    return s:messages[a:k]
  else
    return printf('Unknown message key: %s', a:k)
  endif
endfunction

function! s:echom(hl, s) abort
  for line in split(a:s, '\r\?\n')
    call s:M.echomsg(a:hl, line)
  endfor
endfunction

function! iced#message#info_str(s) abort
  call s:echom('MoreMsg', a:s)
endfunction

function! iced#message#warning_str(s) abort
  call s:echom('WarningMsg', a:s)
endfunction

function! iced#message#error_str(s) abort
  call s:echom('ErrorMsg', a:s)
endfunction

function! iced#message#info(k) abort
  call iced#message#info_str(iced#message#get(a:k))
endfunction

function! iced#message#warning(k) abort
  call iced#message#warning_str(iced#message#get(a:k))
endfunction

function! iced#message#error(k) abort
  call iced#message#error_str(iced#message#get(a:k))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
