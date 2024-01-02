let s:save_cpo = &cpoptions
set cpoptions&vim

let s:supported_programs = {
      \ 'babashka': 'bb --socket-repl %s',
      \ }

function! s:start_and_connect(port, cmd) abort
  let cmd = printf(a:cmd, a:port)
  call iced#job_start(cmd)

  call iced#message#echom('connecting')
  let result = iced#util#wait({->
        \ empty(iced#repl#connect('socket_repl', a:port, {'verbose': v:false}))},
        \ 3000)

  if result
    call iced#message#info('connected_to', printf('port %s', a:port))
  else
    call iced#message#error('connect_error')
  endif
endfunction

function! iced#socket_repl#connect#supported_programs() abort
  return keys(s:supported_programs)
endfunction

function! iced#socket_repl#connect#instant(program) abort
  let cmd = get(s:supported_programs, a:program)
  if empty(cmd)
    return iced#message#warning('unknown', a:program)
    return
  endif

  return iced#script#bb_empty_port({port -> s:start_and_connect(port, cmd)})
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
