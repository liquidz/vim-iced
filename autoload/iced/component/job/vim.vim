let s:save_cpo = &cpoptions
set cpoptions&vim

let s:job = {}

function! s:job.start(command, options) abort
  return job_start(a:command, a:options)
endfunction

function! s:job.stop(job_id) abort
  return job_stop(a:job_id)
endfunction

function! s:job.is_job_id(x) abort
  return type(a:x) == v:t_job
endfunction

function! s:job.info(job_id) abort
  return job_info(a:job_id)
endfunction

function! s:job.sendraw(job, string) abort
  return ch_sendraw(a:job, a:string)
endfunction

function! s:job.close_stdin(job) abort
  return ch_close_in(job_getchannel(a:job))
endfunction

function! iced#component#job#vim#start(_) abort
  call iced#util#debug('start', 'vim job')
  return s:job
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
