let s:save_cpo = &cpoptions
set cpoptions&vim

let s:job = {}
function! s:job.start(command, options) abort
  let options = {}
  if has_key(a:options, 'out_cb')
    let options['on_stdout'] = {j,d,e -> a:options['out_cb'](j, d)}
  endif
  if has_key(a:options, 'close_cb')
    let options['on_exit'] = {j,d,e -> a:options['close_cb'](j)}
  endif
  return jobstart(a:command, options)
endfunction

function! s:job.stop(job_id) abort
  return jobstop(a:job_id)
endfunction

function! s:job.is_job_id(x) abort
  return type(a:x) == v:t_number && a:x > 0
endfunction

function! iced#component#job#neovim#start(_) abort
  call iced#util#debug('start', 'neovim job')
  return s:job
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
