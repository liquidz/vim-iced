let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#cljs#figwheel_sidecar#get_env(callback, _) abort
  return a:callback({
        \ 'name': 'figwheel-sidecar',
        \ 'pre-code': {-> '(do (require ''figwheel-sidecar.repl-api) (figwheel-sidecar.repl-api/start-figwheel!))'},
        \ 'env-code': {-> '(figwheel-sidecar.repl-api/repl-env)'},
        \ 'post-code': {-> '(figwheel-sidecar.repl-api/stop-figwheel!)'},
        \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
