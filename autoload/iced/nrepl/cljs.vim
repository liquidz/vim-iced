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
  elseif session_key ==# 'cljs' && ns !=# 'cljs.user'
    call s:switch_session_to_clj()
  endif
endfunction

let g:iced#cljs#default_env = get(g:, 'iced#cljs#default_env', 'figwheel')
let s:using_env_key = ''

let s:env = {
    \ 'figwheel': {-> iced#nrepl#cljs#figwheel#get_env()},
    \ 'nashorn': {-> iced#nrepl#cljs#nashorn#get_env()},
    \ 'graaljs': {-> iced#nrepl#cljs#graaljs#get_env()},
    \ 'custom': {-> iced#nrepl#cljs#custom#get_env()},
    \ }

function! iced#nrepl#cljs#repl(env_key) abort
  let env_key = iced#compat#trim(empty(a:env_key) ? g:iced#cljs#default_env : a:env_key)
  if !has_key(s:env, env_key)
    return iced#message#error('invalid_cljs_env')
  endif

  if iced#nrepl#current_session_key() ==# 'clj' && empty(s:using_env_key)
    let s:using_env_key = env_key
    let env = s:env[s:using_env_key]()
    call env['start']()
  endif
endfunction

function! iced#nrepl#cljs#quit() abort
  if iced#nrepl#current_session_key() ==# 'cljs'
    call iced#nrepl#eval#repl(':cljs/quit')

    if !empty(s:using_env_key)
      let env = s:env[s:using_env_key]()
      call env['stop']()
      let s:using_env_key = ''
    endif
  endif
endfunction

" c.f. :h :command-completion-custom
function! iced#nrepl#cljs#env_complete(arg_lead, cmd_line, cursor_pos) abort
  return join(keys(s:env), "\n")
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
