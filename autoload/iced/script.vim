let s:save_cpo = &cpoptions
set cpoptions&vim

function! iced#script#empty_port(callback) abort
  if !executable('bb')
    call iced#promise#sync(iced#system#get('installer').install, ['bb'], 10000)
  endif

  let command = printf('bb %s/clj/script/empty_port.clj', g:vim_iced_home)
  return iced#system#get('job_out').redir(command, a:callback)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
