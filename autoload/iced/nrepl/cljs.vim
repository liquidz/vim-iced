let s:save_cpo = &cpo
set cpo&vim

function! s:switch_session_to_cljs() abort
  let repl_session = iced#nrepl#repl_session()
  let cljs_session = iced#nrepl#sync#clone(repl_session)
  call iced#nrepl#set_session('cljs', cljs_session)
  call iced#nrepl#change_current_session('cljs')
  call iced#message#info('started_cljs_repl')
endfunction

function! s:switch_session_to_clj() abort
  call iced#nrepl#sync#close(iced#nrepl#cljs_session())
  call iced#nrepl#set_session('cljs', '')
  call iced#nrepl#change_current_session('clj')
  call iced#message#info('quitted_cljs_repl')
endfunction

function! iced#nrepl#cljs#switch_session(resp) abort
  if !has_key(a:resp, 'ns') || !has_key(a:resp, 'session') || a:resp['session'] !=# iced#nrepl#repl_session()
    return
  endif

  let ns = a:resp['ns']
  let session_key = iced#nrepl#current_session_key()
  if session_key ==# 'clj' && ns ==# 'cljs.user'
    call s:switch_session_to_cljs()
    call iced#hook#run('session_switched', {'session': 'cljs'})
  elseif session_key ==# 'cljs' && ns !=# 'cljs.user'
    call s:switch_session_to_clj()
    call iced#hook#run('session_switched', {'session': 'clj'})
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
  if iced#nrepl#current_session_key() ==# 'cljs'
    call iced#nrepl#eval#repl(':cljs/quit')

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
  endif
endfunction

" c.f. :h :command-completion-custom
function! iced#nrepl#cljs#env_complete(arg_lead, cmd_line, cursor_pos) abort
  return join(keys(s:env), "\n")
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
