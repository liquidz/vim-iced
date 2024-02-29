let s:save_cpo = &cpo
set cpo&vim

let s:build_id = ''

function! s:pre_code() abort
  return '(require ''figwheel.main.api)'
endfunction

function! s:env_code() abort
  " NOTE: use `serve` mode like this document
  "       https://figwheel.org/docs/vim.html
  " c.f.https://github.com/bhauman/figwheel-main/blob/v0.2.11/src/figwheel/main/api.clj#L66
  let raw_code = printf('(try %s %s (catch Exception _ %s))',
       \ printf('(figwheel.main.api/start {:mode :serve} "%s")', s:build_id),
       \ printf('(figwheel.main.api/cljs-repl "%s")', s:build_id),
       \ printf('(cider.piggieback/cljs-repl (figwheel.main.api/repl-env "%s"))', s:build_id),
       \ )
  return {'raw': raw_code}
endfunction

function! s:post_code() abort
  let code = printf('(figwheel.main.api/stop "%s")', s:build_id)
  let s:build_id = ''
  return code
endfunction

function! iced#nrepl#cljs#figwheel_main#get_env(callback, options) abort
  if len(a:options) <= 0
    return iced#message#get('argument_missing', 'build-id is required.')
  endif

  let s:build_id = a:options[0]
  return a:callback({
        \ 'name': 'figwheel-main',
        \ 'pre-code': funcref('s:pre_code'),
        \ 'env-code': funcref('s:env_code'),
        \ 'post-code': funcref('s:post_code'),
        \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
