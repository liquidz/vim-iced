let s:save_cpo = &cpoptions
set cpoptions&vim

let g:iced#nrepl#ns#refresh_before_fn = get(g:, 'iced#nrepl#ns#refresh_before_fn', '')
let g:iced#nrepl#ns#refresh_after_fn = get(g:, 'iced#nrepl#ns#refresh_after_fn', '')
let g:iced#nrepl#ns#does_load_for_new_ns = get(g:, 'iced#nrepl#ns#does_load_for_new_ns', v:true)

let s:V = vital#iced#new()
let s:D = s:V.import('Data.Dict')

let s:create_ns_code = join([
      \ '(when-not (clojure.core/find-ns ''%s)',
      \ '  (clojure.core/create-ns ''%s))',
      \ ])

function! s:buffer_ns_created() abort
  let b:iced_ns_created = 1
  return v:true
endfunction

function! iced#nrepl#ns#create() abort
  if exists('b:iced_ns_created') | return | endif
  if !iced#nrepl#is_connected() | return | endif

  let ns_name = iced#nrepl#ns#name_by_buf()
  if ns_name ==# '' | return | endif

  let create_code = printf(s:create_ns_code, ns_name, ns_name)
  " NOTE: For midje user, requiring ns leads running tests.
  "       So these users should set v:false to g:iced#nrepl#ns#does_load_for_new_ns
  let Require_fn = (g:iced#nrepl#ns#does_load_for_new_ns == v:true)
        \ ? function('iced#nrepl#ns#load_current_file')
        \ : function('iced#nrepl#ns#eval')

  call iced#nrepl#eval(create_code, {resp ->
      \ (get(resp, 'value', 'nil') ==# 'nil')
      \ ? s:buffer_ns_created()
      \ : iced#promise#call(Require_fn, []).then({_ -> s:buffer_ns_created()})
      \ })
  return ns_name
endfunction

function! iced#nrepl#ns#is_created() abort
  return exists('b:iced_ns_created')
        \ && b:iced_ns_created == 1
endfunction

function! iced#nrepl#ns#get() abort
  let view = winsaveview()
  let reg_save = @@
  let code = ''

  try
    if iced#nrepl#ns#util#search() == 0
      return ''
    endif
    let code = iced#paredit#get_outer_list_raw()
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry

  return code
endfunction

function! iced#nrepl#ns#name_by_var(...) abort
  let session = get(a:, 1, iced#nrepl#current_session())
  " NOTE: wait for ever
  let resp = iced#nrepl#sync#eval('(ns-name *ns*)', {'session_id': session, 'timeout': v:null})
  if type(resp) != v:t_dict || !has_key(resp, 'value')
    return ''
  endif
  return resp['value']
endfunction

function! iced#nrepl#ns#name_by_buf() abort
  let view = winsaveview()
  let reg_save = @@

  try
    if iced#nrepl#ns#util#search() == 0
      return ''
    endif

    " Move to next element head
    silent normal! l
    call sexp#move_to_adjacent_element('n', 0, 1, 0, 0)

    " skip meta
    let p = getcurpos()
    if searchpos('\^', 'cn') == [p[1], p[2]]
      call sexp#move_to_adjacent_element('n', 0, 1, 0, 0)
    endif

    return matchstr(getline('.'), '[a-zA-Z0-9.\-]\+', col('.') - 1)
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

function! iced#nrepl#ns#name() abort
  let ns_name = iced#nrepl#ns#name_by_buf()
  return (empty(ns_name))
        \ ? iced#nrepl#ns#name_by_var()
        \ : ns_name
endfunction

function! iced#nrepl#ns#eval(callback) abort
  let code = iced#nrepl#ns#get()
  if empty(code)
    call a:callback('')
  else
    call iced#nrepl#eval(
          \ code,
          \ {'verbose': v:false, 'ns': iced#nrepl#ns#name_by_buf()},
          \ {resp -> s:buffer_ns_created() && a:callback(resp)})
  endif
endfunction

function! iced#nrepl#ns#require(ns_name, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  let code = printf('(clojure.core/require ''%s)', a:ns_name)
  call iced#nrepl#eval(
        \ code,
        \ {'verbose': v:false, 'ns': iced#nrepl#ns#name_by_buf()},
        \ {resp -> s:buffer_ns_created() && a:callback(resp)})
endfunction

function! s:cljs_load_file(callback) abort
  if !iced#nrepl#is_connected()
    return iced#message#error('not_connected')
  endif

  call iced#nrepl#send({
      \ 'op': 'eval',
      \ 'session': iced#nrepl#current_session(),
      \ 'id': iced#nrepl#id(),
      \ 'code': printf('(load-file "%s")', expand('%:p')),
      \ 'callback': a:callback,
      \ })
endfunction

function! s:loaded(resp, callback) abort
  if has_key(a:resp, 'error')
    return iced#nrepl#eval#err(a:resp['error'])
  elseif has_key(a:resp, 'err')
    return iced#nrepl#eval#err(a:resp['err'])
  endif

  return a:callback(a:resp)
endfunction

function! s:required(resp) abort
  call iced#message#info('required')
  call iced#hook#run('ns_required', {'response': a:resp})
  return v:true
endfunction

function! iced#nrepl#ns#load_current_file(...) abort
  if !iced#nrepl#is_connected() && !iced#nrepl#auto_connect()
    return
  endif

  let Cb = get(a:, 1, funcref('s:required'))
  let Cb = (type(Cb) == v:t_func) ? Cb : funcref('s:required')
  if ! iced#nrepl#check_session_validity() | return | endif

  if iced#nrepl#is_supported_op('load-file')
    call iced#nrepl#load_file({resp -> s:buffer_ns_created() && s:loaded(resp, Cb)})
  else
    call s:cljs_load_file({resp -> s:buffer_ns_created() && Cb(resp)})
  endif
endfunction

function! s:all_reloaded(resp) abort
  call iced#message#info('all_reloaded')
  call iced#hook#run('ns_all_reloaded', {'response': a:resp})
endfunction

function! iced#nrepl#ns#reload_all() abort
  let Cb = {_ -> iced#message#info('all_reloaded')}
  let Cb = funcref('s:all_reloaded')
  if ! iced#nrepl#check_session_validity() | return | endif

  if iced#nrepl#current_session_key() ==# 'clj'
    let ns = iced#nrepl#ns#name()
    let code = printf('(clojure.core/require ''%s :reload-all)', ns)
    call iced#nrepl#eval(code, {'ns': ns},  Cb)
  else
    call s:cljs_load_file(Cb)
  endif
endfunction

function! iced#nrepl#ns#does_exist(ns_name) abort
  " FIXME: Workaround for supporting cider-nrepl 0.21.0
  "        In cljs, find-ns is bootstrap only.
  "        https://github.com/clojure/clojurescript/blob/v1.10/src/main/cljs/cljs/core.cljs#L11405
  if iced#nrepl#current_session_key() ==# 'cljs' | return v:true | endif
  let find_ns_result = iced#nrepl#sync#eval(printf('(if (find-ns ''%s) :ok :ng)', a:ns_name))
  return (has_key(find_ns_result, 'value') && find_ns_result['value'] ==# ':ok') ? v:true : v:false
endfunction

function! iced#nrepl#ns#alias_dict(ns_name) abort
  let kondo = iced#system#get('clj_kondo')

  if kondo.is_analyzed()
    let aliases = kondo.ns_aliases(a:ns_name)

    if !aliases
      return {}
    endif

    for k in keys(aliases)
      if len(aliases[k]) > 0
        let aliases[k] = aliases[k][0]
      else
        unlet aliases[k]
      endif
    endfor

    return aliases
  else
    try
      " NOTE: To avoid evaluating `ns-aliases` with non-existing namespace.
      if !iced#nrepl#ns#does_exist(a:ns_name)
        return {}
      endif

      let resp = iced#promise#sync('iced#nrepl#op#cider#ns_aliases', [a:ns_name], v:null)
      return get(resp, 'ns-aliases', {})
    catch
      return {}
    endtry
  endif
endfunction

function! s:__find_existing_alias(ns_name, aliases) abort
  let aliases = get(a:aliases, iced#nrepl#current_session_key(), {})

  for k in keys(aliases)
    if k ==# 'sut' | continue | endif
    for ns in aliases[k]
      if ns ==# a:ns_name
        return k
      endif
    endfor
  endfor
  return ''
endfunction

function! iced#nrepl#ns#find_existing_alias(ns_name, callback) abort
  let kondo = iced#system#get('clj_kondo')
  if kondo.is_analyzed()
    let aliases = kondo.ns_aliases()
    let resp = {}
    let resp[iced#nrepl#current_session_key()] = aliases
    return a:callback(s:__find_existing_alias(a:ns_name, resp))
  elseif iced#nrepl#is_supported_op('namespace-aliases')
    return iced#nrepl#op#refactor#all_ns_aliases({resp ->
          \ a:callback(s:__find_existing_alias(a:ns_name, resp))})
  else
    return iced#message#error('not_supported')
  endif
endfunction

"" Clear all caches related to namespace
function! iced#nrepl#ns#clear_cache() abort
  call iced#nrepl#op#refactor#__clear_cache()
endfunction

function! iced#nrepl#ns#unalias(alias_name, ...) abort
  let ns_name = iced#nrepl#ns#name()
  let alias_name = empty(a:alias_name) ? iced#nrepl#var#cword() : a:alias_name
  let Callback = get(a:, 1, '')

  if type(Callback) != v:t_func
    let Callback = {_ -> iced#message#info('unaliased', alias_name)}
  endif

  let code = printf("(ns-unalias '%s '%s)", ns_name, alias_name)
  return iced#nrepl#eval(code, {'ns': ns_name}, Callback)
endfunction

function! iced#nrepl#ns#yank_name() abort
  call setreg('""', iced#nrepl#ns#name_by_buf())
endfunction

function! s:__gen_refresh_option() abort
  let option = {}

  if ! empty(g:iced#nrepl#ns#refresh_before_fn)
    let option['before'] = g:iced#nrepl#ns#refresh_before_fn
  endif

  if ! empty(g:iced#nrepl#ns#refresh_after_fn)
    let option['after'] = g:iced#nrepl#ns#refresh_after_fn
  endif

  return option
endfunction

function! s:__refresh(message, resp) abort
  for resp in iced#util#ensure_array(a:resp)
    if has_key(resp, 'err')
      return iced#message#error_str(resp['err'])
    endif
  endfor

  call iced#message#info('finish_to_refresh', a:message)
endfunction

function! iced#nrepl#ns#refresh() abort
  let message = 'all changed files'
  let option = s:__gen_refresh_option()

  call iced#message#info('start_to_refresh', message)
  return iced#promise#call('iced#nrepl#op#cider#refresh', [option])
        \.then(funcref('s:__refresh', [message]))
endfunction

function! iced#nrepl#ns#refresh_all() abort
  let message = 'all files'
  let option = s:__gen_refresh_option()
  let option['all'] = v:true

  call iced#message#info('start_to_refresh', message)
  return iced#promise#call('iced#nrepl#op#cider#refresh', [option])
        \.then(funcref('s:__refresh', [message]))
endfunction

function! iced#nrepl#ns#refresh_clear() abort
  return iced#promise#call('iced#nrepl#op#cider#refresh_clear', [])
        \.then({_ -> iced#message#info('cleared')})
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
