let s:save_cpo = &cpo
set cpo&vim

let s:build_id = ''

function! s:env_code() abort
  " NOTE: figwheel.main.api/start will start cljs-repl also
  let raw_code = printf('(try %s (catch Exception _ %s))',
        \ printf('(figwheel.main.api/start "%s")', s:build_id),
        \ printf('(cider.piggieback/cljs-repl (figwheel.main.api/repl-env "%s"))', s:build_id),
        \ )
  return {'raw': raw_code}
endfunction

function! s:post_code() abort
  let s:build_id = ''
  return printf('(figwheel.main.api/stop "%s")', s:build_id)
endfunction

function! iced#nrepl#cljs#figwheel_main#get_env(options) abort
  if len(a:options) <= 0
    return iced#message#get('argument_missing', 'build-id is required.')
  endif

  let s:build_id = a:options[0]
  return {'pre-code': {-> '(require ''figwheel.main.api)'},
        \ 'env-code': funcref('s:env_code'),
        \ 'post-code': funcref('s:post_code')}
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
