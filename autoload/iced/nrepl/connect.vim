let s:save_cpo = &cpoptions
set cpoptions&vim

let s:nrepl_port_file = '.nrepl-port'
let s:running_job = -1
let s:is_auto_connecting = v:false

let g:iced#nrepl#connect#iced_command = get(g:, 'iced#nrepl#connect#iced_command', 'iced')
let g:iced#nrepl#connect#clj_command = get(g:, 'iced#nrepl#connect#clj_command', 'clojure')
let g:iced#nrepl#connect#jack_in_command = get(g:, 'iced#nrepl#connect#jack_in_command',
      \ printf('%s repl', g:iced#nrepl#connect#iced_command))
let g:iced#nrepl#connect#auto_connect_timeout_ms = get(g:, 'iced#nrepl#connect#auto_connect_timeout_ms', 5000)

function! s:detect_port_from_nrepl_port_file() abort

	call themis#log('s:detect_port_from_nrepl_port_file %s', getcwd())
	call themis#log('FIXME %s %s', s:nrepl_port_file, readdir(getcwd()))

  let path = findfile(s:nrepl_port_file, '.;')
  if empty(path)
    return v:false
  else
    let lines = readfile(path)
    return (empty(lines))
          \ ? v:false
          \ : str2nr(lines[0])
  endif
endfunction

function! s:detect_shadow_cljs_nrepl_port() abort
  let dot_shadow_cljs = finddir('.shadow-cljs', '.;')
  if empty(dot_shadow_cljs) | return v:false | endif

  let path = findfile('nrepl.port', dot_shadow_cljs)
  return (empty(path)
        \ ? v:false
        \ : str2nr(readfile(path)[0]))
endfunction

function! s:__connect_nrepl(port) abort
  call iced#repl#connect('nrepl', a:port)
  return v:true
endfunction

function! s:__connect_shadow_cljs(port) abort
  call iced#repl#connect('nrepl', a:port, {'cljs_env': 'shadow-cljs'})
  return v:true
endfunction

function! iced#nrepl#connect#auto(...) abort
  let verbose = get(a:, 1, v:true)
  let shadow_cljs_port = s:detect_shadow_cljs_nrepl_port()
  let nrepl_port = s:detect_port_from_nrepl_port_file()

  if shadow_cljs_port && nrepl_port
    call iced#selector({
          \ 'candidates': ['nREPL', 'shadow-cljs'],
          \ 'accept': {_, s -> (s ==# 'nREPL')
          \                    ? s:__connect_nrepl(nrepl_port)
          \                    : s:__connect_shadow_cljs(shadow_cljs_port)}
          \ })
    return v:true
  else
    if shadow_cljs_port
      return s:__connect_shadow_cljs(shadow_cljs_port)
    elseif nrepl_port
      return s:__connect_nrepl(nrepl_port)
    endif
  endif

  if verbose | call iced#message#error('no_port_file') | endif
  return v:false
endfunction

function! s:wait_for_auto_connection(_) abort
  call iced#util#wait(
        \ {-> !iced#nrepl#connect#auto(v:false)},
        \ g:iced#nrepl#connect#auto_connect_timeout_ms)
  let s:is_auto_connecting = v:false
endfunction

function! s:jack_in_callback(_, out) abort
  let connected = iced#nrepl#is_connected()

  for line in iced#util#ensure_array(a:out)
    if empty(line) | continue | endif
    let line = iced#util#delete_color_code(line)

    if connected
      call iced#buffer#stdout#append(line)
    else
      echo line
      "" NOTE: Leiningen, Boot and Clojure CLI print the same text like below.
      if stridx(line, 'nREPL server started') != -1
        let s:is_auto_connecting = v:true
        call iced#system#get('timer').start(
              \ 500,
              \ funcref('s:wait_for_auto_connection'),
              \ )
      endif
    endif
  endfor
endfunction

function! iced#nrepl#connect#jack_in(...) abort
  if iced#nrepl#is_connected()
    return iced#message#info('already_connected')
  endif

  if !executable(g:iced#nrepl#connect#iced_command)
    return iced#message#error('not_executable', g:iced#nrepl#connect#iced_command)
  endif

  let job = iced#system#get('job')
  if job.is_job_id(s:running_job)
    return iced#message#error('already_running')
  endif

  let command = get(a:, 1, g:iced#nrepl#connect#jack_in_command)
  let s:running_job = job.start(command, {
        \ 'out_cb': funcref('s:jack_in_callback'),
        \ })
endfunction

function! s:__instant_clj() abort
  if !executable(g:iced#nrepl#connect#clj_command)
    return iced#message#error('not_executable', g:iced#nrepl#connect#clj_command)
  endif

  let cmd = printf('%s repl --instant', g:iced#nrepl#connect#iced_command)
  call iced#nrepl#connect#jack_in(cmd)
endfunction

function! s:try_connecting_to_babashka(port) abort
  try
    return iced#repl#connect('nrepl', a:port, {
          \ 'with_iced_nrepl': v:false,
          \ 'verbose': v:false,
          \ })
  catch
    return v:false
  endtry
endfunction

function! s:__instant_babashka(port) abort
  " NOTE: A job in vim may terminate when outputting long texts such as stack traces.
  "       So ignoring the standard output etc.
  let cmd = ['sh', '-c', printf('bb --nrepl-server %s > /dev/null 2>&1', a:port)]
  let s:running_job = iced#job_start(cmd)

  let s:is_auto_connecting = v:true
  call iced#message#echom('connecting')
  let result = iced#util#wait({->
        \ empty(s:try_connecting_to_babashka(a:port))},
        \ 3000)
  let s:is_auto_connecting = v:false

  if result
    call iced#message#info('connected_to', printf('port %s', a:port))
  else
    call iced#message#error('connect_error')
  endif
endfunction

function! iced#nrepl#connect#instant(program) abort
  if iced#nrepl#is_connected()
    return iced#message#info('already_connected')
  endif

  if a:program ==# 'babashka'
    return iced#script#empty_port({port -> s:__instant_babashka(port)})
  else
    return s:__instant_clj()
  endif
endfunction

function! iced#nrepl#connect#reset() abort
  if s:is_auto_connecting | return | endif

  let job = iced#system#get('job')
  if job.is_job_id(s:running_job)
    call job.stop(s:running_job)
  endif

  let s:running_job = -1
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
