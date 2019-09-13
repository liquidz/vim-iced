let s:save_cpo = &cpoptions
set cpoptions&vim

let s:nrepl_port_file = '.nrepl-port'

let g:iced#nrepl#connect#jack_in_command = get(g:, 'iced#nrepl#connect#jack_in_command', 'iced repl')

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
  let port = s:detect_shadow_cljs_nrepl_port()

  if !port
    let port = s:detect_port_from_nrepl_port_file()
  endif

  if port
    call iced#nrepl#connect(port)
    return v:true
  endif

  if verbose | call iced#message#error('no_port_file') | endif
  return v:false
endfunction

function! s:wait_for_auto_connection(id) abort
  if iced#nrepl#connect#auto(v:false)
    call iced#di#get('timer').stop(a:id)
  endif
endfunction

function! s:jack_in_callback(_, out) abort
  for line in iced#util#ensure_array(a:out)
    let line = iced#util#delete_color_code(line)
    echo line

    "" NOTE: Leiningen, Boot and Clojure CLI print the same text like below.
    if stridx(line, 'nREPL server started') != -1 && !iced#nrepl#is_connected()
      call iced#di#get('timer').start(
            \ 500,
            \ funcref('s:wait_for_auto_connection'),
            \ {'repeat': 10})
    endif
  endfor
endfunction

function! iced#nrepl#connect#jack_in(...) abort
  if !executable('iced')
    return iced#message#error('not_executable', 'iced')
  endif

  let command = get(a:, 1, g:iced#nrepl#connect#jack_in_command)
  call iced#compat#job_start(command, {
        \ 'out_cb': funcref('s:jack_in_callback'),
        \ })
endfunction

function! iced#nrepl#connect#instant() abort
  if !executable('clojure')
    return iced#message#error('not_executable', 'clojure')
  endif

  call iced#nrepl#connect#jack_in('iced repl --instant')
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
