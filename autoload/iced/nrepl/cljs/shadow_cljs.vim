let s:save_cpo = &cpo
set cpo&vim

let s:build_id = ''

function! iced#nrepl#cljs#shadow_cljs#get_env(options) abort
  if len(a:options) <= 0
    return iced#message#get('argument_missing', 'build-id is required.')
  endif

  let s:build_id = trim(a:options[0], ' :')
  " HACK: For shadow-cljs, vim-iced ignores quit detecting
  "       because shadow-cljs returns exact current ns instead of 'cljs.user'
  return {'does_use_piggieback': v:false,
        \ 'pre-code': {-> '(require ''shadow.cljs.devtools.api)'},
        \ 'env-code': {-> {'raw': printf('(do (shadow/watch :%s) (shadow/nrepl-select :%s))', s:build_id, s:build_id) }},
        \ 'ignore-quit-detecting': v:true,
        \ }
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
