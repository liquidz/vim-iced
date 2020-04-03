let s:save_cpo = &cpoptions
set cpoptions&vim

let s:socket_repl = {
      \ 'connect': function('iced#socket_repl#connect'),
      \ 'disconnect': function('iced#socket_repl#disconnect'),
      \ 'env': 'socket_repl',
      \ 'eval_code': function('iced#socket_repl#eval'),
      \ 'eval_outer_top_list': function('iced#socket_repl#eval_outer_top_list'),
      \ 'eval_at_mark': function('iced#repl#eval_at_mark'),
      \ 'is_connected': function('iced#socket_repl#is_connected'),
      \ 'status': function('iced#socket_repl#status'),
      \ 'load_current_file': function('iced#socket_repl#load_current_file'),
      \ 'document_open': function('iced#socket_repl#document#open'),
      \ 'document_popup_open': function('iced#socket_repl#document#popup_open'),
      \ 'complete_candidates': function('iced#socket_repl#complete#candidates'),
      \ }

function! iced#component#repl#socket_repl#start(_) abort
  call iced#util#debug('start', 'socket-repl')
  return s:socket_repl
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
