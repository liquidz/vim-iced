let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:bb_setup() abort
  if !executable('bb')
    call iced#promise#sync(iced#system#get('installer').install, ['bb'], 10000)
  endif
endfunction

function! iced#script#bb_empty_port(callback) abort
  call s:bb_setup()
  let command = printf('bb --prn %s/clj/script/empty_port.clj', g:vim_iced_home)
  return iced#system#get('job_out').redir(command, a:callback)
endfunction

function! s:nbb_command() abort
  if executable('nbb')
    return 'nbb'
  elseif executable('deno')
    return 'deno run -A npm:nbb@latest'
  endif

  throw 'nbb or deno is not found.'
endfunction

function! iced#script#nbb_empty_port(callback) abort
  let cmd = s:nbb_command()
  let command = printf('%s %s/clj/script/nbb_empty_port.cljs', cmd, g:vim_iced_home)
  return iced#system#get('job_out').redir(command, a:callback)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
