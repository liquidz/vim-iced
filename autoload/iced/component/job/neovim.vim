let s:save_cpo = &cpoptions
set cpoptions&vim

let s:job = {
      \ 'exitvals': {},
      \ }

function! s:on_exit(options, job, exit_code, event_type) abort dict
  let self.exitvals[a:job] = a:exit_code
	return a:options['close_cb'](a:job)
endfunction

function! s:job.start(command, options) abort
  let options = iced#util#select_keys(a:options, ['cwd'])
  if has_key(a:options, 'out_cb')
    let options['on_stdout'] = {j,d,e -> a:options['out_cb'](j, d)}
  endif
  if has_key(a:options, 'err_cb')
    let options['on_stderr'] = {j,d,e -> a:options['err_cb'](j, d)}
  endif
  if has_key(a:options, 'close_cb')
    let options['on_exit'] = funcref('s:on_exit', [a:options], self)
  endif
  return jobstart(a:command, options)
endfunction

function! s:job.stop(job_id) abort
  return jobstop(a:job_id)
endfunction

function! s:job.is_job_id(x) abort
  return type(a:x) == v:t_number && a:x > 0
endfunction

function! s:job.info(job_id) abort
  return {'exitval': get(self.exitvals, a:job_id, 0)}
endfunction

function! s:job.sendraw(job_id, string) abort
  return jobsend(a:job_id, a:string)
endfunction

function! s:job.close_stdin(job_id) abort
  return chanclose(a:job_id, 'stdin')
endfunction

function! iced#component#job#neovim#start(_) abort
  call iced#util#debug('start', 'neovim job')
  return s:job
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
