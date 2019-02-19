let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#cljs#graaljs#get_env(_) abort
  return {'pre-code': {-> '(require ''cljs.repl.graaljs)'},
        \ 'env-code': {-> '(cljs.repl.graaljs/repl-env)'}}
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
