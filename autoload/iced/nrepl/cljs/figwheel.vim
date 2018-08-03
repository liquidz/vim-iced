let s:save_cpo = &cpo
set cpo&vim

function! s:code(code) abort
  return printf('(do (require ''figwheel-sidecar.repl-api) %s)', a:code)
endfunction

function! s:start_repl(callback) abort
  call iced#nrepl#send({
      \ 'id': iced#nrepl#eval#id(),
      \ 'op': 'eval',
      \ 'code': s:code('(cider.piggieback/cljs-repl (figwheel-sidecar.repl-api/repl-env))'),
      \ 'session': iced#nrepl#repl_session(),
      \ 'callback': a:callback,
      \ })
endfunction

function! s:start_figwheel(callback) abort
  call iced#nrepl#send({
      \ 'id': iced#nrepl#eval#id(),
      \ 'op': 'eval',
      \ 'code': s:code('(figwheel-sidecar.repl-api/start-figwheel!)'),
      \ 'session': iced#nrepl#repl_session(),
      \ 'callback': {_ -> s:start_repl(a:callback)},
      \ })
endfunction

function! s:stop_figwheel() abort
  call iced#nrepl#sync#send({
      \ 'id': iced#nrepl#eval#id(),
      \ 'op': 'eval',
      \ 'code': s:code('(figwheel-sidecar.repl-api/stop-figwheel!)'),
      \ 'session': iced#nrepl#repl_session(),
      \ })
endfunction

function! iced#nrepl#cljs#figwheel#get_env() abort
  return {
      \ 'start': funcref('s:start_figwheel'),
      \ 'stop': funcref('s:stop_figwheel'),
      \ }
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
