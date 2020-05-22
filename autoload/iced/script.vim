let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:setup() abort
  if !executable('bb')
    call iced#promise#sync(iced#system#get('installer').install, ['bb'], 10000)
  endif
endfunction

function! iced#script#empty_port(callback) abort
  call s:setup()
  let command = printf('bb %s/clj/script/empty_port.clj', g:vim_iced_home)
  return iced#system#get('job_out').redir(command, a:callback)
endfunction

function! iced#script#shadow_cljs_validation(shadow_cljs_config_path, callback) abort
  call s:setup()
  let command = printf('bb %s/clj/script/shadow_cljs_validation.clj %s %s',
        \ g:vim_iced_home,
        \ a:shadow_cljs_config_path,
        \ g:vim_iced_home,
        \ )

  return iced#system#get('job_out').redir(command, a:callback)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
