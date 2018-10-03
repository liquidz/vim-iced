let s:save_cpo = &cpo
set cpo&vim

let s:ch = {
    \ 'env': 'neovim',
    \ }

function! s:handle(job_id) abort
  return {'job_id': a:job_id}
endfunction

function! s:job_id(handle) abort
  return a:handle['job_id']
endfunction

function! s:data_rely(data) abort
  if type(a:data) == type([])
    return join(a:data, "\n")
  endif
  return a:data
endfunction

function! s:ch.open(address, options) abort
  if !executable('nc')
    return
  endif

  let [host, port] = split(a:address, ':')
  let opts = {}

  if has_key(a:options, 'callback')
    let Cb = {job_id, data, _ -> a:options.callback(s:handle(job_id), s:data_rely(data))}
    let opts['on_stdout'] = Cb
    let opts['on_stderr'] = Cb
  endif

  let id = jobstart(['nc', host, port], opts)
  let handle = s:handle(id)
  let handle['address'] = a:address
  return handle
endfunction

function! s:ch.close(handle) abort
  return jobstop(s:job_id(a:handle))
endfunction

function! s:ch.status(handle) abort
  let id = s:job_id(a:handle)
  try
    return (jobpid(id) > 0) ? 'open' : 'closed'
  catch /E900:/
    return 'closed'
  endtry
endfunction

function! s:ch.sendraw(handle, string) abort
  let id = s:job_id(a:handle)
  return jobsend(id, a:string)
endfunction

function! iced#channel#neovim#new() abort
  return s:ch
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
