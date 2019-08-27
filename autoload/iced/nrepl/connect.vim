let s:save_cpo = &cpoptions
set cpoptions&vim

let s:nrepl_port_file = '.nrepl-port'

function! s:detect_port_from_nrepl_port_file() abort
  let path = findfile(s:nrepl_port_file, '.;')
  return (empty(path)
        \ ? v:false
        \ : str2nr(readfile(path)[0]))
endfunction

function! s:detect_shadow_cljs_nrepl_port() abort
  let dot_shadow_cljs = finddir('.shadow-cljs', '.;')
  if empty(dot_shadow_cljs) | return v:false | endif

  let path = findfile('nrepl.port', dot_shadow_cljs)
  return (empty(path)
        \ ? v:false
        \ : str2nr(readfile(path)[0]))
endfunction

function! iced#nrepl#connect#auto() abort
  let port = s:detect_shadow_cljs_nrepl_port()

  if !port
    let port = s:detect_port_from_nrepl_port_file()
  endif

  if port
    call iced#nrepl#connect(port)
    return v:true
  endif

  call iced#message#error('no_port_file')
  return v:false
endfunction

function! s:instant_repl_callback(_, out) abort
  let line = iced#util#delete_color_code(a:out)
  echo line
  if stridx(line, 'nREPL server started') != -1 && !iced#nrepl#is_connected()
    call iced#util#future(function('iced#nrepl#connect#auto'))
  endif
endfunction

function! iced#nrepl#connect#instant() abort
  if !executable('iced')
    return iced#message#error('not_executable', 'iced')
  endif
  if !executable('clojure')
    return iced#message#error('not_executable', 'clojure')
  endif

  call iced#compat#job_start('iced repl --instant', {
        \ 'out_cb': funcref('s:instant_repl_callback'),
        \ })
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
