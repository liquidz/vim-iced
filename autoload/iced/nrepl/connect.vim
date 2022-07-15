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
let g:iced#nrepl#connect#prefer = get(g:, 'iced#nrepl#connect#prefer', '')

function! s:detect_port_from_nrepl_port_file(threshold_time) abort
  let path = findfile(s:nrepl_port_file, '.;')
  if empty(path)
    return v:false
  endif

  if getftime(path) < a:threshold_time
    return v:false
  endif

  let lines = readfile(path)
  return (empty(lines))
        \ ? v:false
        \ : str2nr(lines[0])
endfunction

function! s:detect_shadow_cljs_nrepl_port(threshold_time) abort
  let dot_shadow_cljs = finddir('.shadow-cljs', '.;')
  if empty(dot_shadow_cljs) | return v:false | endif

  let path = findfile('nrepl.port', dot_shadow_cljs)
  if empty(path)
    return v:false
  endif

  if getftime(path) < a:threshold_time
    return v:false
  endif

  let lines = readfile(path)
  return (empty(lines))
        \ ? v:false
        \ : str2nr(lines[0])
endfunction

function! s:__connect_nrepl(port) abort
  call iced#repl#connect('nrepl', a:port)
  return v:true
endfunction

function! s:__connect_shadow_cljs(port) abort
  call iced#repl#connect('nrepl', a:port, {'cljs_env': 'shadow-cljs'})
  return v:true
endfunction

function! s:__connect_selected(selected) abort
  let name = a:selected['type']
  let port = a:selected['port']
  return (name ==# 'nrepl')
        \ ? s:__connect_nrepl(port)
        \ : s:__connect_shadow_cljs(port)
endfunction

function! iced#nrepl#connect#auto(...) abort
  let verbose = get(a:, 1, v:true)
  let threshold_time = get(a:, 2, 0)
  let shadow_cljs_port = s:detect_shadow_cljs_nrepl_port(threshold_time)
  let nrepl_port = s:detect_port_from_nrepl_port_file(threshold_time)
  let candidates = []

  if nrepl_port
    let candidates += [{
         \ 'label': 'nREPL',
         \ 'type': 'nrepl',
         \ 'port': nrepl_port}]
  endif

  if shadow_cljs_port
    let candidates += [{
         \ 'label': 'shadow-cljs',
         \ 'type': 'shadow-cljs',
         \ 'port': shadow_cljs_port}]
  endif

  " Only 'function' hook type is available
  let hook_results = iced#hook#run('connect_prepared',
       \ candidates,
       \ {'shell': v:false,
       \  'eval': v:false,
       \  'command': v:false})
  let filtered_candidates = filter(hook_results, {_, v -> type(v) == v:t_list})[0]

  let filtered_count = len(filtered_candidates)

  " There is only one candidate, so connect to it.
  if filtered_count == 1
    return s:__connect_selected(filtered_candidates[0])
  " There are some candidates, but preferred option is defined.
  " If the preferred candidate exists, connect to it.
  elseif filtered_count > 1 && ! empty(g:iced#nrepl#connect#prefer)
    for candidate in filtered_candidates
      if get(candidate, 'type', '') ==# g:iced#nrepl#connect#prefer
        return s:__connect_selected(candidate)
      endif
    endfor
  " There are some candidates, select one to connect.
  elseif filtered_count > 1
    call iced#selector({
         \ 'candidates': map(copy(filtered_candidates), {_, v -> v['label']}),
         \ 'accept': {_, s -> s:__connect_selected(
         \                      filter(copy(filtered_candidates), {_, v -> v['label'] ==# s})[0])},
         \ })
    return v:true
  endif

  if verbose | call iced#message#error('no_port_file') | endif
  return v:false
endfunction

function! s:wait_for_auto_connection(threshold_time) abort
  call iced#util#wait(
        \ {-> !iced#nrepl#connect#auto(v:false, a:threshold_time)},
        \ g:iced#nrepl#connect#auto_connect_timeout_ms)
  let s:is_auto_connecting = v:false
endfunction

function! s:jack_in_callback(threshold_time, _, out) abort
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
              \ {_ -> s:wait_for_auto_connection(a:threshold_time)},
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

  let current_time = localtime()
  let command = get(a:, 1, g:iced#nrepl#connect#jack_in_command)
  let s:running_job = job.start(command, {
        \ 'out_cb': funcref('s:jack_in_callback', [current_time]),
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

function! s:try_connecting_to_nbb(port) abort
  try
    return iced#repl#connect('nrepl', a:port, {
          \ 'with_iced_nrepl': v:false,
          \ 'initial_session': 'cljs',
          \ 'verbose': v:false,
          \ })
  catch
    return v:false
  endtry
endfunction

function! s:__instant_nbb(port) abort
  " NOTE: A job in vim may terminate when outputting long texts such as stack traces.
  "       So ignoring the standard output etc.
  let cmd = ['sh', '-c', printf('nbb nrepl-server :port %s > /dev/null 2>&1', a:port)]
  let s:running_job = iced#job_start(cmd)

  let s:is_auto_connecting = v:true
  call iced#message#echom('connecting')
  let result = iced#util#wait({->
        \ empty(s:try_connecting_to_nbb(a:port))},
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
  elseif a:program ==# 'nbb'
    return iced#script#empty_port({port -> s:__instant_nbb(port)})
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
