let s:save_cpo = &cpoptions
set cpoptions&vim

let s:vim = {} " {{{
function! s:vim.start(command, options) abort
  return job_start(a:command, a:options)
endfunction

function! s:vim.stop(job_id) abort
  return job_stop(a:job_id)
endfunction

function! s:vim.is_job_id(x) abort
  return type(a:x) == v:t_job
endfunction
" }}}

let s:neovim = {} " {{{
function! s:neovim.start(command, options) abort
  let options = {}
  if has_key(a:options, 'out_cb')
    let options['on_stdout'] = {j,d,e -> a:options['out_cb'](j, d)}
  endif
  if has_key(a:options, 'close_cb')
    let options['on_exit'] = {j,d,e -> a:options['close_cb'](j)}
  endif
  return jobstart(a:command, options)
endfunction

function! s:neovim.stop(job_id) abort
  return jobstop(a:job_id)
endfunction

function! s:neovim.is_job_id(x) abort
  return type(a:x) == v:t_number && a:x > 0
endfunction
" }}}

function! s:on_out_out(_, out) abort dict
  for out in iced#util#ensure_array(a:out)
    let self.result = self.result . out
  endfor
endfunction

function! s:on_out_close(_) abort dict
  call self.callback(self.result)
endfunction

function! iced#component#job#start(_) abort
  call iced#util#debug('start', 'job')
  "return has('nvim') ? s:neovim : s:vim
  let job =  has('nvim') ? s:neovim : s:vim

  " common {{{
  function! job.out(command, callback) abort
    let d = {'result': '', 'callback': a:callback}
    call self.start(a:command, {
          \ 'out_cb': funcref('s:on_out_out', d),
          \ 'close_cb': funcref('s:on_out_close', d),
          \ })
  endfunction
  " }}}

  return job
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
" vim:fdm=marker:fdl=0
