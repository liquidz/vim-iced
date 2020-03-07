let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:read_code(filename) abort
  return join(readfile(printf('%s/clj/template/socket_repl_%s', g:vim_iced_home, a:filename)), "\n")
endfunction

" workaround for planck warning
function! s:planck_handler(lines) abort
  if len(a:lines) == 3 && stridx(a:lines[1], 'WARNING') == 0
    let out = substitute(a:lines[2], '\(^"\|"$\)', '', 'g')
    return split(out, '\\n')
  endif
  return a:lines
endfunction

function! iced#socket_repl#complete#candidates(base, callback) abort
  let repl_type = iced#socket_repl#repl_type()
  let Handler = {x -> x}

  " Planck
  if repl_type ==# 'cljs.user'
    let code = s:read_code('complete_planck.cljs')
    let Handler = funcref('s:planck_handler')
  elseif repl_type ==# 'lumo'
    let code = s:read_code('complete_lumo.cljs')
  else
    let code = s:read_code('complete_default.clj')
  endif

  call iced#socket_repl#eval(printf(code, a:base), {'callback': {resp ->
       \ a:callback(Handler(iced#socket_repl#out#lines(resp)))}})
  return v:true
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
