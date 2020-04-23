let s:save_cpo = &cpoptions
set cpoptions&vim

let s:nrepl_port_file = '.nrepl-port'
let s:jack_in_job = -1

let g:iced#nrepl#connect#iced_command = get(g:, 'iced#nrepl#connect#iced_command', 'iced')
let g:iced#nrepl#connect#clj_command = get(g:, 'iced#nrepl#connect#clj_command', 'clojure')
let g:iced#nrepl#connect#jack_in_command = get(g:, 'iced#nrepl#connect#jack_in_command',
      \ printf('%s repl', g:iced#nrepl#connect#iced_command))

function! s:detect_port_from_nrepl_port_file() abort
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

function! iced#nrepl#connect#auto(...) abort
  let verbose = get(a:, 1, v:true)
  let shadow_cljs_port = s:detect_shadow_cljs_nrepl_port()
  let nrepl_port = s:detect_port_from_nrepl_port_file()

  if shadow_cljs_port && nrepl_port
    call iced#selector({
          \ 'candidates': ['nREPL', 'shadow-cljs'],
          \ 'accept': {_, s -> iced#repl#connect('nrepl', (s ==# 'nREPL') ? nrepl_port : shadow_cljs_port)}
          \ })
    return v:true
  else
    let port = shadow_cljs_port ? shadow_cljs_port : nrepl_port

    if port
      call iced#repl#connect('nrepl', port)
      return v:true
    endif
  endif

  if verbose | call iced#message#error('no_port_file') | endif
  return v:false
endfunction

function! s:wait_for_auto_connection(id) abort
  if iced#nrepl#connect#auto(v:false)
    call iced#system#get('timer').stop(a:id)
  endif
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
        call iced#system#get('timer').start(
              \ 500,
              \ funcref('s:wait_for_auto_connection'),
              \ {'repeat': 10})
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
  if job.is_job_id(s:jack_in_job)
    return iced#message#error('already_running')
  endif

  let command = get(a:, 1, g:iced#nrepl#connect#jack_in_command)
  let s:jack_in_job = job.start(command, {
        \ 'out_cb': funcref('s:jack_in_callback'),
        \ })
endfunction

function! iced#nrepl#connect#instant() abort
  if !executable(g:iced#nrepl#connect#clj_command)
    return iced#message#error('not_executable', g:iced#nrepl#connect#clj_command)
  endif

  let cmd = printf('%s repl --instant', g:iced#nrepl#connect#iced_command)
  call iced#nrepl#connect#jack_in(cmd)
endfunction

function! iced#nrepl#connect#reset() abort
  let job = iced#system#get('job')
  if job.is_job_id(s:jack_in_job)
    call job.stop(s:jack_in_job)
  endif

  let s:jack_in_job = -1
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
