let s:save_cpo = &cpoptions
set cpoptions&vim

let s:build_id = ''

function! s:validate_config() abort
  let file = findfile('shadow-cljs.edn', '.;')
  if empty(file) | return | endif

  let resp = iced#promise#sync('iced#script#shadow_cljs_validation', [file])
  let value = trim(resp, '"')

  if empty(value) | return '' | endif
  return printf("%s\n%s",
        \ substitute(value, '\\n', '\n', 'g'),
        \ iced#message#get('missing_config'))
endfunction

function! iced#nrepl#cljs#shadow_cljs#get_env(options) abort
  if len(a:options) <= 0
    return iced#message#get('argument_missing', 'build-id is required.')
  endif

  let s:build_id = trim(a:options[0], ' :')
  " HACK: For shadow-cljs, vim-iced ignores quit detecting
  "       because shadow-cljs returns exact current ns instead of 'cljs.user'
  return {'does_use_piggieback': v:false,
        \ 'pre-code': {-> '(require ''shadow.cljs.devtools.api)'},
        \ 'env-code': {-> {'raw': printf('(do (shadow.cljs.devtools.api/watch :%s) (shadow.cljs.devtools.api/nrepl-select :%s))', s:build_id, s:build_id) }},
        \ 'ignore-quit-detecting': v:true,
        \ 'warning': s:validate_config(),
        \ }
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
