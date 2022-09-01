let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:not_supported(...) abort
  return iced#message#error('not_supported')
endfunction

let s:socket_repl = {
      \ 'connect': function('iced#socket_repl#connect'),
      \ 'disconnect': function('iced#socket_repl#disconnect'),
      \ 'env': 'socket_repl',
      \ 'eval_code': function('iced#socket_repl#eval'),
      \ 'eval_code_isolatedy': funcref('s:not_supported'),
      \ 'eval_outer_top_list': function('iced#socket_repl#eval_outer_top_list'),
      \ 'eval_at_mark': function('iced#repl#eval_at_mark'),
      \ 'eval_in_context_at_mark': function('iced#repl#eval_in_context_at_mark'),
      \ 'eval_last_outer_top_list': function('iced#repl#eval_last_outer_top_list'),
      \ 'is_connected': function('iced#socket_repl#is_connected'),
      \ 'status': function('iced#socket_repl#status'),
      \ 'load_current_file': function('iced#socket_repl#load_current_file'),
      \ 'document_open': function('iced#socket_repl#document#open'),
      \ 'document_popup_open': function('iced#socket_repl#document#popup_open'),
      \ 'complete_candidates': function('iced#socket_repl#complete#candidates'),
      \ 'autocmd_bufenter': function('iced#socket_repl#auto#bufenter'),
      \ 'autocmd_bufread': function('iced#socket_repl#auto#bufread'),
      \ 'autocmd_bufwritepost': function('iced#repl#auto#bufwritepost'),
      \ }

function! iced#component#repl#socket_repl#start(_) abort
  call iced#util#debug('start', 'socket-repl')
  return s:socket_repl
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
