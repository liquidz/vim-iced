let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:S = s:V.import('Data.String')
let s:L = s:V.import('Data.List')

let s:last_test_var = ''

function! s:error_message(test) abort
  if has_key(a:test, 'context') && !empty(a:test['context'])
    return printf('%s: %s', a:test['var'], a:test['context'])
  else
    return a:test['var']
  endif
endfunction

function! s:summary(resp) abort
  for resp in iced#util#ensure_array(a:resp)
    if has_key(resp, 'summary')
      let summary = resp['summary']
      return {
          \ 'summary': printf('%s: Ran %d assertions, in %d test functions. %d failures, %d errors.',
          \                   get(resp, 'testing-ns', ''),
          \                   summary['test'], summary['var'],
          \                   summary['fail'], summary['error']),
          \ 'is_success': ((summary['fail'] + summary['error']) == 0),
          \ }
    endif
  endfor

  return ''
endfunction

function! s:extract_actual_values(test) abort
  if !has_key(a:test, 'diffs') || type(a:test['diffs']) != type([])
    return {'actual': iced#compat#trim(get(a:test, 'actual', ''))}
  endif

  let diffs = a:test['diffs'][0]
  return {
      \ 'actual': iced#compat#trim(diffs[0]),
      \ 'diffs': printf("- %s\n+ %s", iced#compat#trim(diffs[1][0]), iced#compat#trim(diffs[1][1])),
      \ }
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
          if test['type'] !=# 'fail' && test['type'] !=# 'error'
            continue
          endif

          let ns_path_resp = iced#nrepl#op#cider#sync#ns_path(ns_name)
          if type(ns_path_resp) != type({}) || !has_key(ns_path_resp, 'path')
            continue
          endif

          let err = {
                  \ 'filename': ns_path_resp['path'],
                  \ 'lnum': test['line'],
                  \ 'text': s:error_message(test),
                  \ 'expected': iced#compat#trim(get(test, 'expected', '')),
                  \ 'type': 'E',
                  \ }
          if test['type'] ==# 'fail'
            call add(errors, extend(copy(err), s:extract_actual_values(test)))
          elseif test['type'] ==# 'error'
            call add(errors, extend(copy(err), {'actual': test['error']}))
          endif
        endfor
      endfor
    endfor
  endfor

  return errors
endfunction

function! s:dict_to_str(d, ...) abort
  let ks = get(a:, 1, keys(a:d))
  let n = len(s:L.max_by(ks, function('len')))
  let res = []

  for k in ks
    if !has_key(a:d, k) || empty(a:d[k])
      continue
    endif

    let vs = split(a:d[k], '\r\?\n')
    call add(res, printf('%' . n . 's: %s', k, vs[0]))
    for v in vs[1:]
      call add(res, printf('%' . n . 's  %s', ' ', v))
    endfor
  endfor

  return join(res, "\n")
endfunction

function! s:out(resp) abort
  if iced#util#has_status(a:resp, 'namespace-not-found')
    return iced#message#error('not_found')
  endif
  
  let errors = s:collect_errors(a:resp)
  let expected_and_actuals = []
  for err in errors
    call iced#sign#place_error(err['lnum'], err['filename'])

    if has_key(err, 'expected') && has_key(err, 'actual')
      let expected_and_actuals = expected_and_actuals + [
          \ printf(';; %s', err['text']),
          \ s:dict_to_str(err, ['expected', 'actual', 'diffs']),
          \ '']
    endif
  endfor

  call iced#buffer#error#show(join(expected_and_actuals, "\n"))
  call iced#qf#set(errors)

  let summary = s:summary(a:resp)
  if summary['is_success']
    call iced#message#info_str(summary['summary'])
  else
    call iced#message#error_str(summary['summary'])
  endif
endfunction

function! s:test(resp) abort
  if has_key(a:resp, 'err')
    call iced#nrepl#eval#err(a:resp['err'])
  elseif has_key(a:resp, 'value')
    let var = a:resp['value']
    let s:last_test_var = var

    let var = substitute(var, '^#''', '', '')
    let i = stridx(var, '/')
    let ns = var[0:i-1]
    let var = var[i+1:]
    echom printf('Testing: %s', var)
    call iced#nrepl#op#cider#test_var(ns, var, funcref('s:out'))
  endif
endfunction

function! iced#nrepl#test#under_cursor() abort
  let ret = iced#paredit#get_current_top_list()
  let code = ret['code']
  if empty(code)
    call iced#message#error('finding_code_error')
  else
    let pos = ret['curpos']
    let option = {'line': pos[1], 'column': pos[2]}
    call iced#sign#unplace_all()
    call iced#nrepl#ns#eval({_ -> iced#nrepl#eval(code, {resp -> s:test(resp)}, option)})
  endif
endfunction

function! iced#nrepl#test#rerun_last() abort
  if empty(s:last_test_var)
    return
  endif
  call s:test({'value': s:last_test_var})
endfunction

function! iced#nrepl#test#ns() abort
  let ns = iced#nrepl#ns#name()
  if !s:S.ends_with(ns, '-test')
    let ns = iced#nrepl#ns#transition#cycle(ns)
  endif

  call iced#sign#unplace_all()
  call iced#message#info('testing')
  call iced#nrepl#op#cider#test_ns(ns, funcref('s:out'))
endfunction

function! iced#nrepl#test#all() abort
  call iced#sign#unplace_all()
  call iced#message#info('testing')
  call iced#nrepl#op#cider#ns_load_all({_ ->
        \ iced#nrepl#op#cider#test_all(funcref('s:out'))})
endfunction

function! iced#nrepl#test#redo() abort
  let view = winsaveview()
  let reg_save = @@

  try
    call iced#sign#unplace_all()
    " vim-sexp: move to top
    silent exe "normal \<Plug>(sexp_move_to_prev_top_element)"
    silent normal! va(y

    let code = @@
    if empty(code)
      call iced#message#error('finding_code_error')
    else
      let pos = getcurpos()
      let option = {'line': pos[1], 'column': pos[2]}
      call iced#message#info('retesting')
      call iced#nrepl#eval(code, {_ -> iced#nrepl#op#cider#retest(funcref('s:out'))}, option)
    endif
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
