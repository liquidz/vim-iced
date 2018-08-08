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
  for resp in iced#util#ensure_array(a:resp)
    if has_key(resp, 'summary')
      let summary = resp['summary']
      return printf('%s: Ran %d assertions, in %d test functions. %d failures, %d errors.',
          \ get(resp, 'testing-ns', ''),
          \ summary['test'], summary['var'],
          \ summary['fail'], summary['error'])
    endif
  endfor

  return v:none
endfunction

function! s:collect_errors(resp) abort
  let errors  = []

  for response in iced#util#ensure_array(a:resp)
    let results = get(response, 'results', {})

    for ns_name in keys(results)
      let ns_results = results[ns_name]

      for test_name in keys(ns_results)
        let test_results = ns_results[test_name]

        for test in test_results
          if test['type'] ==# 'fail'
            let ns_path_resp = iced#nrepl#cider#sync#ns_path(ns_name)
            if type(ns_path_resp) == type({}) && has_key(ns_path_resp, 'path')
              call add(errors, {
                  \ 'filename': ns_path_resp['path'],
                  \ 'lnum': test['line'],
                  \ 'text': s:error_message(test),
                  \ })
            endif
          elseif test['type'] ==# 'error'
            let ns_path_resp =  iced#nrepl#cider#sync#ns_path(ns_name)
            if type(ns_path_resp) == type({}) && has_key(ns_path_resp, 'path')
              call add(errors, {
                  \ 'filename': ns_path_resp['path'],
                  \ 'lnum': test['line'],
                  \ 'text': test['error'],
                  \ })
            endif
          endif
        endfor
      endfor
    endfor
  endfor

  return errors
endfunction

function! s:out(resp) abort
  call iced#util#echo_messages(s:summary(a:resp))

  let errors = s:collect_errors(a:resp)
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
    echom printf('Testing: %s', var)
    call iced#nrepl#cider#test_var(var, funcref('s:out'))
  endif
endfunction

function! iced#nrepl#test#under_cursor() abort
  let view = winsaveview()
  " vim-sexp: move to top
  silent exe "normal \<Plug>(sexp_move_to_prev_top_element)"

  let reg_save = @@
  try
    silent normal! va(y
    let code = @@
    call iced#nrepl#ns#eval({_ -> iced#nrepl#eval(code, {resp -> s:test(resp)})})
  finally
    let @@ = reg_save
    call winrestview(view)
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
