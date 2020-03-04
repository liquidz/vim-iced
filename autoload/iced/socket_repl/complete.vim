let s:save_cpo = &cpoptions
set cpoptions&vim

let s:complete_code = join(readfile(printf('%s/clj/template/socket_repl_complete.clj', g:vim_iced_home)), "\n")

function! iced#socket_repl#complete#candidates(base, callback) abort
  let code = printf(s:complete_code, a:base)
  call iced#socket_repl#eval(code, {'callback': {resp ->
       \ a:callback(iced#socket_repl#out#lines(resp))}})
  return v:true
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
