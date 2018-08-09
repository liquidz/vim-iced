let s:save_cpo = &cpo
set cpo&vim

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
    \ }

function! iced#message#get(k) abort
  if has_key(s:messages, a:k)
    return s:messages[a:k]
  else
    return printf('Unknown message key: %s', a:k)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
