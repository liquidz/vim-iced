let s:save_cpo = &cpoptions
set cpoptions&vim

let g:iced#cljs#default_env = get(g:, 'iced#cljs#default_env', 'figwheel-sidecar')
let s:using_env = {}
let s:env_options = []
let s:quit_code = ':cljs/quit'

let s:env = {
    \ 'figwheel-sidecar': function('iced#nrepl#cljs#figwheel_sidecar#get_env'),
    \ 'figwheel-main': function('iced#nrepl#cljs#figwheel_main#get_env'),
    \ 'shadow-cljs': function('iced#nrepl#cljs#shadow_cljs#get_env'),
    \ }

function! s:set_cljs_session(original_cljs_session) abort
  " WARN: An exception occurs if an evaluation error occurs in the CLONED cljs session.
  "       c.f. https://github.com/liquidz/vim-iced/issues/91
  "       So `original_cljs_session` must be setted to cljs session.
  let cloned_cljs_session = iced#nrepl#sync#clone(a:original_cljs_session)

  call iced#nrepl#set_session('cljs', a:original_cljs_session)
  call iced#nrepl#set_session('clj', cloned_cljs_session)
  " Quit **CLONED** cljs session to work as a clj session
  return iced#nrepl#eval#code(s:quit_code, {'session': 'clj', 'ignore_session_validity': v:true, 'verbose': v:false , 'ignore_ns': v:true})
endfunction

function! s:unset_cljs_session() abort
  call iced#nrepl#sync#close(iced#nrepl#cljs_session())
  call iced#nrepl#set_session('cljs', '')
endfunction

function! iced#nrepl#cljs#check_switching_session(eval_resp, evaluated_code) abort
  if !has_key(a:eval_resp, 'ns') || !has_key(a:eval_resp, 'session')
    return iced#promise#resolve('')
  endif

  let eval_session = a:eval_resp['session']
  let eq_to_clj_session = (eval_session ==# iced#nrepl#clj_session())
  let eq_to_cljs_session = (eval_session ==# iced#nrepl#cljs_session())

  if !eq_to_clj_session && !eq_to_cljs_session
    return iced#promise#resolve('')
  endif

  let ns = a:eval_resp['ns']
  let ext = expand('%:e')

  if eq_to_clj_session && ns ==# g:iced#nrepl#init_cljs_ns
    " Switch to CLJS session from CLJ session
    let p = s:set_cljs_session(eval_session)
    if ext !=# 'clj'
      call iced#nrepl#change_current_session('cljs')
      call iced#hook#run('session_switched', {'session': 'cljs'})
    endif

    call iced#message#info('started_cljs_repl')
    return p

  elseif eq_to_cljs_session
      \ && !get(s:using_env, 'ignore-quit-detecting', v:false)
      \ && a:evaluated_code ==# s:quit_code
    " Quit CLJS session
    call s:unset_cljs_session()
    call iced#nrepl#change_current_session('clj')

    call iced#message#info('quitted_cljs_repl')
    call iced#hook#run('session_switched', {'session': 'clj'})
  endif

  return iced#promise#resolve('')
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

  let opt = get(a:, 1, {})
  let does_use_piggieback = get(opt, 'does_use_piggieback', v:true)

  if does_use_piggieback && !iced#nrepl#system#piggieback_enabled()
    call iced#message#error('no_piggieback')
    return v:false
  endif

  if iced#nrepl#current_session_key() ==# 'clj'
    let pre_code = get(opt, 'pre', '')

    if type(a:code) == v:t_dict && has_key(a:code, 'raw')
      let code = printf('(do %s %s)', pre_code, a:code['raw'])
    else
      let code = printf('(do %s (cider.piggieback/cljs-repl %s))', pre_code, a:code)
    endif
    call iced#nrepl#eval#code(code, {'ignore_session_validity': v:true, 'ignore_ns': v:true})
    return v:true
  endif
  return v:false
endfunction

function! iced#nrepl#cljs#stop_repl(...) abort
  if iced#nrepl#cljs_session() !=# ''
    call iced#nrepl#eval#code(s:quit_code, {'session': 'cljs', 'ignore_session_validity': v:true, 'ignore_ns': v:true})

    let opt = get(a:, 1, {})
    let post_code = get(opt, 'post', '')
    if !empty(post_code)
      call iced#nrepl#eval#code(post_code, {'ignore_session_validity': v:true, 'ignore_ns': v:true})
    endif
    return v:true
  endif
  return v:false
endfunction

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

    let warning = get(env, 'warning', '')
    if !empty(warning)
      call iced#message#warning_str(warning)
      let res = iced#system#get('io').input(iced#message#get('confirm_proceeding'))
      if res !=# '' && res !=# 'y' && res !=# 'Y'
        return iced#message#error('canceled_cljs_repl')
      endif
    endif

    let Pre_code_f = get(env, 'pre-code', '')
    let Env_code_f = get(env, 'env-code', '')

    if type(Env_code_f) != v:t_func
      return iced#message#error('invalid_cljs_env')
    endif

    let pre_code = type(Pre_code_f) == v:t_func ? Pre_code_f() : ''
    let env_code = Env_code_f()

    let opt = copy(env)
    call extend(opt, {'pre': pre_code})
    if iced#nrepl#cljs#start_repl(env_code, opt)
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

let &cpoptions = s:save_cpo
unlet s:save_cpo
