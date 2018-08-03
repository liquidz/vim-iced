let s:save_cpo = &cpo
set cpo&vim

function! s:error_message(test) abort
  let msg = [
      \ has_key(a:test, 'context') ? printf('%s <%s>', a:test['var'], a:test['context'])
      \                            : a:test['var'],
      \ printf('expected: %s', trim(a:test['expected'])),
      \ printf('actual: %s', trim(a:test['actual'])),
      \ ]
  return join(msg, ', ')
endfunction

function! s:summary(resp) abort
  for resp in (type(a:resp) == type([]) ? a:resp : [a:resp])
    if has_key(resp, 'summary')
      let summary = resp['summary']
      let msg = [
          \ printf('Tested %d namespaces', summary['ns']),
          \ printf('Ran %d assertions, in %d test functions', summary['test'], summary['var']),
          \ printf('%d failures', summary['fail']),
          \ ]
      return join(msg, "\n")
    endif
  endfor

  return v:none
endfunction

function! s:out(resp) abort
  let responses = (type(a:resp) == type([]) ? a:resp : [a:resp])
  let errors  = []

  for response in responses
    let results = get(response, 'results', {})

    for ns_name in keys(results)
      let ns_results = results[ns_name]

      for test_name in keys(ns_results)
        let test_results = ns_results[test_name]

        for test in test_results
          if test['type'] ==# 'fail'
            let ns_path_resp =  iced#nrepl#cider#sync#ns_path(ns_name)
            call add(errors, {
                \ 'filename': ns_path_resp['path'],
                \ 'lnum': test['line'],
                \ 'text': s:error_message(test),
                \ })
          endif
        endfor
      endfor
    endfor
  endfor

  call iced#util#echo_messages(s:summary(a:resp))
  call setqflist(errors , 'r')
  if empty(errors)
    cclose
  else
    cwindow
    silent! doautocmd QuickFixCmdPost make
  endif
endfunction

function! s:test(resp) abort
  if has_key(a:resp, 'value')
    let var = a:resp['value']
    let i = stridx(var, '/')
    let var = var[i+1:]
    call iced#nrepl#cider#test_var(var, funcref('s:out'))
  endif
endfunction

function! iced#nrepl#test#under_cursor() abort
  let current_pos = getcurpos()
  " vim-sexp: move to top
  silent exe "normal \<Plug>(sexp_move_to_prev_top_element)"

  let reg_save = @@
  try
    silent normal! va(y
    let code = @@
    call iced#nrepl#eval(code, {resp -> s:test(resp)})
  finally
    let @@ = reg_save
    call cursor(current_pos[1], current_pos[2])
  endtry
endfunction

function! iced#nrepl#test#ns() abort
  let ns = iced#nrepl#ns#name()
  call iced#nrepl#cider#test_ns(ns, funcref('s:out'))
endfunction

function! iced#nrepl#test#all() abort
  call iced#nrepl#cider#test_all(funcref('s:out'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
