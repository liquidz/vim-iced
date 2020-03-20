let s:save_cpo = &cpoptions
set cpoptions&vim

let s:out = {
      \ 'job': '',
      \ }

function! s:on_out_out(_, out) abort dict
  for out in iced#util#ensure_array(a:out)
    let self.result = self.result . out
  endfor
endfunction

function! s:on_out_close(_) abort dict
  call self.callback(self.result)
endfunction

function! s:out.redir(command, callback) abort
  let d = {'result': '', 'callback': a:callback}
  call self.job.start(a:command, {
        \ 'out_cb': funcref('s:on_out_out', d),
        \ 'close_cb': funcref('s:on_out_close', d),
        \ })
endfunction

function! iced#component#job#out#start(this) abort
  call iced#util#debug('start', 'job_out')
  let d = deepcopy(s:out)
  let d['job'] = a:this['job']
  return d
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
