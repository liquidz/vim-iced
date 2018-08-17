let s:save_cpo = &cpo
set cpo&vim

function! s:code(code) abort
  return printf('(do (require ''figwheel-sidecar.repl-api) %s)', a:code)
endfunction

function! s:start_figwheel() abort
  let code = printf('(do %s %s)',
      \ s:code('(figwheel-sidecar.repl-api/start-figwheel!)'),
      \ s:code('(cider.piggieback/cljs-repl (figwheel-sidecar.repl-api/repl-env))'),
      \ )
  call iced#nrepl#eval#repl(code)
endfunction

function! s:stop_figwheel() abort
  call iced#nrepl#eval#repl(s:code('(figwheel-sidecar.repl-api/stop-figwheel!)'))
endfunction

function! iced#nrepl#cljs#figwheel#get_env() abort
  return {
      \ 'start': funcref('s:start_figwheel'),
      \ 'stop': funcref('s:stop_figwheel'),
      \ }
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
