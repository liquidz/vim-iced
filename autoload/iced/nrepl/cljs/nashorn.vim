let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#cljs#nashorn#get_env(_) abort
  return {'pre-code': {-> '(require ''cljs.repl.nashorn)'},
        \ 'env-code': {-> '(cljs.repl.nashorn/repl-env)'}}
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
