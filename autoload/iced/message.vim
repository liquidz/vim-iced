let s:save_cpo = &cpo
set cpo&vim

let s:messages = {
    \ 'auto_connect':      'Auto connecting...',
    \ 'not_connected':     'Not connected.',
    \ 'try_connect':       'Not connected. Try `:IcedConnect <port>`',
    \ 'connected':         'Connected.',
    \ 'reading':           'FIXME reading',
    \ 'not_found':         'Not found.',
    \ 'required':          'Required.',
    \ 'timeout':           'Timed out.',
    \ 'invalid_cljs_env':  'Invalid CLJS environment.',
    \ 'started_cljs_repl': 'CLJS repl is started.',
    \ 'quitted_cljs_repl': 'CLJS repl is quitted.',
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
