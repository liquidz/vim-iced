let s:save_cpo = &cpoptions
set cpoptions&vim

let s:build_id = ''

let s:get_build_ids_code = '(do'
      \  . '  (require ''shadow.cljs.devtools.api)'
      \  . '  (filter shadow.cljs.devtools.api/worker-running? '
      \  . '          (shadow.cljs.devtools.api/get-build-ids))'
      \  . '  )'

function! s:validate_config() abort
  let file = findfile('shadow-cljs.edn', '.;')
  if empty(file) | return | endif

  let warn = ''
  for line in readfile(file)
    if stridx(line, 'iced-nrepl') != -1
      let warn = 'Now, iced command supports shadow-cljs. Please see https://liquidz.github.io/vim-iced/#clojurescript_shadow_cljs'
      break
    endif
  endfor

  return warn
endfunction

function! iced#nrepl#cljs#shadow_cljs#get_env(options) abort
  if len(a:options) > 0
    let s:build_id = trim(a:options[0], ' :')
  else
    " fetch running build ids
    let build_ids = get(iced#eval_and_read(s:get_build_ids_code), 'value', [])
    if empty(build_ids) && len(a:options) <= 0
      return iced#message#get('argument_missing', 'build-id is required.')
    endif

    let build_id_count = len(build_ids)
    if build_id_count == 0
      return iced#message#get('argument_missing', 'build-id is required.')
    elseif build_id_count == 1
      let s:build_id = trim(build_ids[0], ' :')
    else
      " select build id
      let p = iced#promise#new({resolve -> iced#selector({'accept': {_, v -> resolve(v)},
            \                                             'candidates': build_ids})})
      let [result, error] = iced#promise#wait(p)
      if !empty(error)
        return iced#message#get('argument_missing', 'build-id is required.')
      endif

      let s:build_id = trim(result, ' :')
    endif
  endif

  " HACK: For shadow-cljs, vim-iced ignores quit detecting
  "       because shadow-cljs returns exact current ns instead of 'cljs.user'
  return {
        \ 'name': 'shadow-cljs',
        \ 'does_use_piggieback': v:false,
        \ 'pre-code': {-> '(require ''shadow.cljs.devtools.api)'},
        \ 'env-code': {-> {'raw': printf('(do (shadow.cljs.devtools.api/watch :%s) (shadow.cljs.devtools.api/nrepl-select :%s))', s:build_id, s:build_id) }},
        \ 'ignore-quit-detecting': v:true,
        \ 'warning': s:validate_config(),
        \ }
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
