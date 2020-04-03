let s:save_cpo = &cpoptions
set cpoptions&vim

let s:nrepl = {
      \ 'connect': function('iced#nrepl#connect'),
      \ 'disconnect': function('iced#nrepl#disconnect'),
      \ 'env': 'nrepl',
      \ 'eval_code': function('iced#nrepl#eval#code'),
      \ 'eval_outer_top_list': function('iced#nrepl#eval#outer_top_list'),
      \ 'eval_at_mark': function('iced#repl#eval_at_mark'),
      \ 'eval_last_outer_top_list': function('iced#repl#eval_last_outer_top_list'),
      \ 'eval_raw': function('iced#nrepl#eval'),
      \ 'is_connected': function('iced#nrepl#is_connected'),
      \ 'status': function('iced#nrepl#status'),
      \ 'load_current_file': function('iced#nrepl#ns#load_current_file'),
      \ 'document_open': function('iced#nrepl#document#open'),
      \ 'document_popup_open': function('iced#nrepl#document#popup_open'),
      \ 'complete_candidates': function('iced#nrepl#complete#candidates'),
      \ }

function! iced#component#repl#nrepl#start(_) abort
  call iced#util#debug('start', 'nrepl')
  return s:nrepl
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
