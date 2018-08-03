let s:save_cpo = &cpo
set cpo&vim

function! s:code(code) abort
  return printf('(do (require ''cljs.repl.nashorn) %s)', a:code)
endfunction

function! s:start_repl(callback) abort
  call iced#nrepl#send({
      \ 'id': iced#nrepl#eval#id(),
      \ 'op': 'eval',
      \ 'code': s:code('(cider.piggieback/cljs-repl (cljs.repl.nashorn/repl-env))'),
      \ 'session': iced#nrepl#repl_session(),
      \ 'callback': a:callback,
      \ })
endfunction

function! iced#nrepl#cljs#nashorn#get_env() abort
  return {
      \ 'start': funcref('s:start_repl'),
      \ 'stop': {-> v:none},
      \ }
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
