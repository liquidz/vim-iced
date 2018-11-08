let s:save_cpo = &cpo
set cpo&vim

function! s:code(code) abort
  return printf('(do (require ''cljs.repl.graaljs) %s)', a:code)
endfunction

function! s:start_repl() abort
  let code = s:code('(cider.piggieback/cljs-repl (cljs.repl.graaljs/repl-env))')
  call iced#nrepl#eval#repl(code)
endfunction

function! iced#nrepl#cljs#graaljs#get_env() abort
  return {
      \ 'start': funcref('s:start_repl'),
      \ 'stop': {-> ''},
      \ }
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
