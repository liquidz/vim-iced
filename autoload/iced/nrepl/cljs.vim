let s:save_cpo = &cpo
set cpo&vim

function! s:switch_session_to_cljs() abort
  " WARN: An exception occurs if an evaluation error occurs in the CLONED cljs session.
  "       c.f. https://github.com/liquidz/vim-iced/issues/91
  "       So `original_cljs_session` must be setted to cljs session.
  let original_cljs_session = iced#nrepl#repl_session()
  let cljs_repl_session = iced#nrepl#sync#clone(original_cljs_session)

  let repl_session = iced#nrepl#sync#clone(original_cljs_session)
  " make repl_session to be CLJ
  call iced#nrepl#sync#eval(':cljs/quit', {'session_id': repl_session})

  call iced#nrepl#set_session('cljs', original_cljs_session)
  call iced#nrepl#set_session('cljs_repl', cljs_repl_session)
  call iced#nrepl#set_session('repl', repl_session)
  call iced#nrepl#change_current_session('cljs')

  let ext = expand('%:e')
  if ext ==# 'cljs' || ext ==# 'cljc'
    call iced#nrepl#ns#in()
  endif

  call iced#message#info('started_cljs_repl')
endfunction

function! s:switch_session_to_clj() abort
  call iced#nrepl#sync#close(iced#nrepl#cljs_session())
  call iced#nrepl#sync#close(iced#nrepl#cljs_repl_session())
  call iced#nrepl#set_session('cljs', '')
  call iced#nrepl#set_session('cljs_repl', '')
  call iced#nrepl#change_current_session('clj')

  let ext = expand('%:e')
  if ext ==# 'clj' || ext ==# 'cljc'
    call iced#nrepl#ns#in()
  endif

  call iced#message#info('quitted_cljs_repl')
endfunction

function! iced#nrepl#cljs#check_switching_session(resp) abort
  if !has_key(a:resp, 'ns') || !has_key(a:resp, 'session') | return | endif

  let session = a:resp['session']
  let eq_to_repl_session = (session ==# iced#nrepl#repl_session())
  let eq_to_cljs_repl_session = (session ==# iced#nrepl#cljs_repl_session())
  if !eq_to_repl_session && !eq_to_cljs_repl_session | return | endif

  let ns = a:resp['ns']
  if eq_to_repl_session && ns ==# 'cljs.user'
    call s:switch_session_to_cljs()
    call iced#hook#run('session_switched', {'session': 'cljs'})
  elseif eq_to_cljs_repl_session && ns !=# 'cljs.user'
    call s:switch_session_to_clj()
    call iced#hook#run('session_switched', {'session': 'clj'})
  endif
endfunction

function! iced#nrepl#cljs#cycle_session() abort
  if iced#nrepl#current_session_key() ==# 'cljs'
    call iced#nrepl#change_current_session('clj')
    call iced#hook#run('session_switched', {'session': 'clj'})
  else
    if empty(iced#nrepl#cljs_session())
      return iced#message#error('no_session', 'cljs')
    else
      call iced#nrepl#change_current_session('cljs')
      call iced#hook#run('session_switched', {'session': 'cljs'})
    endif
  endif
endfunction

function! iced#nrepl#cljs#start_repl(code, ...) abort
  if !iced#nrepl#is_connected() && !iced#nrepl#auto_connect() | return v:false | endif
  if !iced#nrepl#system#piggieback_enabled()
    call iced#message#error('no_piggieback')
    return v:false
  endif

  if iced#nrepl#current_session_key() ==# 'clj'
    let opt = get(a:, 1, {})
    let pre_code = get(opt, 'pre', '')

    if type(a:code) == v:t_dict && has_key(a:code, 'raw')
      let code = printf('(do %s %s)', pre_code, a:code['raw'])
    else
      let code = printf('(do %s (cider.piggieback/cljs-repl %s))', pre_code, a:code)
    endif
    call iced#nrepl#eval#repl(code)
    return v:true
  endif
  return v:false
endfunction

function! iced#nrepl#cljs#stop_repl(...) abort
  if iced#nrepl#cljs_session() !=# ''
    call iced#nrepl#eval#repl(':cljs/quit', 'cljs_repl')

    let opt = get(a:, 1, {})
    let post_code = get(opt, 'post', '')
    if !empty(post_code)
      call iced#nrepl#eval#repl(post_code)
    endif
    return v:true
  endif
  return v:false
endfunction

let g:iced#cljs#default_env = get(g:, 'iced#cljs#default_env', 'figwheel-sidecar')
let s:using_env = {}
let s:env_options = []

let s:env = {
    \ 'figwheel-sidecar': function('iced#nrepl#cljs#figwheel_sidecar#get_env'),
    \ 'figwheel-main': function('iced#nrepl#cljs#figwheel_main#get_env'),
    \ 'nashorn': function('iced#nrepl#cljs#nashorn#get_env'),
    \ 'graaljs': function('iced#nrepl#cljs#graaljs#get_env'),
    \ }

function! iced#nrepl#cljs#reset() abort
  let s:using_env = {}
  let s:env_options = []
endfunction

function! iced#nrepl#cljs#start_repl_via_env(env_key, ...) abort
  let env_key = trim(empty(a:env_key) ? g:iced#cljs#default_env : a:env_key)
  if !has_key(s:env, env_key)
    return iced#message#error('invalid_cljs_env')
  endif

  if empty(s:using_env)
    let env = s:env[env_key](a:000)
    if type(env) != v:t_dict | return iced#message#error_str(env) | endif

    let Pre_code_f = get(env, 'pre-code', '')
    let Env_code_f = get(env, 'env-code', '')

    if type(Env_code_f) != v:t_func
      return iced#message#error('invalid_cljs_env')
    endif

    let pre_code = type(Pre_code_f) == v:t_func ? Pre_code_f() : ''
    let env_code = Env_code_f()
    if iced#nrepl#cljs#start_repl(env_code, {'pre': pre_code})
      let s:using_env = env
    endif
  endif
endfunction

function! iced#nrepl#cljs#stop_repl_via_env() abort
  if !empty(s:using_env)
    let Post_code_f = get(s:using_env, 'post-code', '')
    let post_code = type(Post_code_f) == v:t_func ? Post_code_f() : ''
    if iced#nrepl#cljs#stop_repl({'post': post_code})
      let s:using_env = {}
    endif
  else
    call iced#nrepl#cljs#stop_repl()
  endif
endfunction

" c.f. :h :command-completion-custom
function! iced#nrepl#cljs#env_complete(arg_lead, cmd_line, cursor_pos) abort
  return join(keys(s:env), "\n")
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
