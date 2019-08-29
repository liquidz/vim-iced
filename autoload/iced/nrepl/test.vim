let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:S = s:V.import('Data.String')
let s:L = s:V.import('Data.List')

let s:last_test = {}
let s:sign_name = 'iced_error'
let g:iced#test#spec_num_tests = get(g:, 'iced#test#spec_num_tests', 10)

" API {{{
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

function! iced#nrepl#test#done(parsed_response) abort
  if empty(a:parsed_response) | return | endif

  let errors = a:parsed_response['errors']
  let summary = a:parsed_response['summary']
  let expected_and_actuals = []

  call iced#sign#unplace_by_name(s:sign_name)

  for err in errors
    if has_key(err, 'lnum')
      call iced#sign#place(s:sign_name, err['lnum'], err['filename'])
    endif

    if has_key(err, 'expected') && has_key(err, 'actual')
          \ && !empty(err['expected']) && !empty(err['actual'])
      let expected_and_actuals = expected_and_actuals + [
          \ printf(';; %s', err['text']),
          \ s:dict_to_str(err, ['expected', 'actual', 'diffs']),
          \ '']
    endif
  endfor

  call iced#buffer#error#show(join(expected_and_actuals, "\n"))
  call iced#qf#set(errors)

  if summary['is_success']
    call iced#message#info_str(summary['summary'])
  else
    call iced#message#error_str(summary['summary'])
  endif

  call iced#hook#run('test_finished', {
        \ 'result': summary['is_success'] ? 'succeeded' : 'failed',
        \ 'summary': summary['summary']})
endfunction
" }}}

" iced#nrepl#test#test_vars_by_ns_name {{{
function! iced#nrepl#test#test_vars_by_ns_name(ns_name) abort
  let resp = iced#nrepl#op#cider#sync#ns_vars(a:ns_name)
  if !has_key(resp, 'ns-vars-with-meta')
    call iced#message#error('ns_vars_error')
    return []
  endif
  let var_dict = resp['ns-vars-with-meta']
  return filter(copy(keys(var_dict)), {_, k -> has_key(var_dict[k], 'test')})
endfunction " }}}

" iced#nrepl#test#fetch_test_vars_by_function_under_cursor {{{
function! s:test_vars(eval_resp, ns_name, callback) abort
  let test_vars = iced#nrepl#test#test_vars_by_ns_name(a:ns_name)
  if empty(test_vars)
    return iced#message#warning('no_test_vars')
  endif

  let var = a:eval_resp['value']
  let var = substitute(var, '^#''', '', '')
  let i = stridx(var, '/')
  let name = (i == -1) ? var : strpart(var, i+1)

  let test_vars = filter(copy(test_vars), {_, v -> stridx(v, name) != -1})
  call map(test_vars, {_, v -> printf('%s/%s', a:ns_name, v)})
  call a:callback(name, test_vars)
endfunction

function! iced#nrepl#test#fetch_test_vars_by_function_under_cursor(ns_name, callback) abort
  let ret = iced#paredit#get_current_top_list()
  let code = ret['code']
  if empty(code) | return iced#message#error('finding_code_error') | endif

  call iced#nrepl#eval(code, {eval_resp ->
        \   (has_key(eval_resp, 'value') && eval_resp['value'] !=# 'nil')
        \   ? iced#nrepl#ns#require(a:ns_name, {_ ->
        \       s:test_vars(eval_resp, a:ns_name, a:callback)})
        \   : iced#message#error('not_found')})
endfunction " }}}

" iced#nrepl#test#under_cursor {{{
function! s:clojure_test_out(resp) abort
  call iced#nrepl#test#done(
        \ iced#nrepl#test#clojure_test#parse(a:resp))
endfunction

function! s:echo_testing_message(query) abort
  if has_key(a:query, 'exactly') && !empty(a:query['exactly'])
    let vars = join(a:query['exactly'], ', ')
    call iced#message#echom('testing_var', vars)
  elseif has_key(a:query, 'ns-query') && !empty(a:query['ns-query'])
        \ && has_key(a:query['ns-query'], 'exactly') && !empty(a:query['ns-query']['exactly'])
    let ns_query = a:query['ns-query']
    let nss = join(ns_query['exactly'], ', ')
    call iced#message#echom('testing_var', nss)
  else
    call iced#message#echom('testing')
  endif
endfunction

function! s:run_test_vars(ns_name, vars) abort
  let query = {
        \ 'ns-query': {'exactly': [a:ns_name]},
        \ 'exactly': a:vars}
  let s:last_test = {'type': 'test-var', 'query': query}
  call s:echo_testing_message(query)
  call iced#nrepl#op#cider#test_var_query(query, funcref('s:clojure_test_out'))
endfunction

function! s:test_ns_required(ns_name, var_name) abort
    let test_vars = iced#nrepl#test#test_vars_by_ns_name(a:ns_name)
    if empty(test_vars)
      return iced#message#warning('no_test_vars_for', a:var_name)
    endif

    let target_test_vars = filter(copy(test_vars), {_, v -> stridx(v, a:var_name) != -1})
    if empty(target_test_vars)
      return iced#message#warning('no_test_vars_for', a:var_name)
    endif

    call map(target_test_vars, {_, v -> printf('%s/%s', a:ns_name, v)})
    call s:run_test_vars(a:ns_name, target_test_vars)
endfunction

function! s:distribute_tests(var_info) abort
  let qualified_var = a:var_info['qualified_var']
  let ns = a:var_info['ns']
  let var_name = a:var_info['var']
  let test_vars = iced#nrepl#test#test_vars_by_ns_name(ns)

  if index(test_vars, var_name) != -1
    " Form under the cursor is a test
    call s:run_test_vars(ns, [qualified_var])
  elseif s:S.ends_with(ns, '-test')
    " Form under the cursor is not a test, and current ns is ns for test
    return iced#message#error('not_found')
  else
    " Form under the cursor is not a test, and current ns is NOT ns for test
    let ns = iced#nrepl#navigate#cycle_ns(ns)
    " HACK: for neovim
    "call iced#nrepl#ns#require(ns, {_ -> s:test_ns_required(ns, var_name)})
    call iced#nrepl#ns#require(ns, {_ ->
          \ iced#util#future({-> s:test_ns_required(ns, var_name)})
          \ })
  endif
endfunction

function! iced#nrepl#test#under_cursor() abort
  " HACK: for neovim
  "call iced#nrepl#var#extract_by_current_top_list(funcref('s:distribute_tests'))
  call iced#nrepl#var#extract_by_current_top_list({resp ->
        \ iced#util#future({-> s:distribute_tests(resp)})
        \ })
endfunction "}}}

" iced#nrepl#test#ns {{{
function! iced#nrepl#test#ns() abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  let ns = iced#nrepl#ns#name()
  let test_vars = iced#nrepl#test#test_vars_by_ns_name(ns)
  if empty(test_vars) && !s:S.ends_with(ns, '-test')
    let ns = iced#nrepl#navigate#cycle_ns(ns)
  endif

  let query = {'ns-query': {'exactly': [ns]}}
  let s:last_test = {'type': 'test-var', 'query': query}

  call s:echo_testing_message(query)
  call iced#nrepl#ns#require(ns, {_ -> iced#nrepl#op#cider#test_var_query(query, funcref('s:clojure_test_out'))})
endfunction " }}}

" iced#nrepl#test#all {{{
function! iced#nrepl#test#all() abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let query = {
        \ 'ns-query': {'project?': 'true', 'load-project-ns?': 'true'}
        \ }
  let s:last_test = {'type': 'test-var', 'query': query}

  call s:echo_testing_message(query)
  call iced#nrepl#op#cider#test_var_query(query, funcref('s:clojure_test_out'))
endfunction " }}}

" iced#nrepl#test#redo {{{
function! iced#nrepl#test#redo() abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let s:last_test = {'type': 'retest'}
  call iced#message#info('retesting')
  call iced#nrepl#op#cider#retest(funcref('s:clojure_test_out'))
endfunction " }}}

" iced#nrepl#test#spec_check {{{
function! s:spec_check(var, resp) abort
  if !has_key(a:resp, 'result') | return iced#message#error('spec_check_error') | endif
  let num_tests = a:resp['num-tests']
  if type(num_tests) != v:t_number
    let num_tests = 0
  endif

  if a:resp['result'] ==# 'OK'
    if num_tests == 0
      let msg = printf('%s: No tests.', a:var)
    else
      let msg = printf('%s: Ran %d tests. Passed.', a:var, num_tests)
    endif
    return iced#message#info_str(msg)
  else
    if has_key(a:resp, 'error')
      let msg = printf('%s: Ran %d tests. Failed because ''%s'' with %s args.',
            \ a:var, num_tests, a:resp['error'], a:resp['failed-input'])
    else
      let msg = printf('%s: Ran %d tests. Failed with %s args.',
            \ a:var, num_tests, a:resp['failed-input'])
    endif
    return iced#message#error_str(msg)
  endif
endfunction

function! s:run_spec_check_by_current_var(num_tests, var_info) abort
  let s:last_test = {
        \ 'type': 'spec-check',
        \ 'var_info': a:var_info,
        \ 'num_tests': a:num_tests}
  let var = a:var_info['qualified_var']

  call iced#nrepl#op#iced#spec_check(var, a:num_tests, {resp -> s:spec_check(var, resp)})
endfunction

function! iced#nrepl#test#spec_check(...) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  let num_tests = get(a:, 1, '')
  let num_tests = str2nr(num_tests)
  if num_tests <= 0
    let num_tests = g:iced#test#spec_num_tests
  endif

  call iced#nrepl#var#extract_by_current_top_list({v ->
        \ s:run_spec_check_by_current_var(num_tests, v)})
endfunction " }}}

" iced#nrepl#test#rerun_last {{{
function! iced#nrepl#test#rerun_last() abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  if empty(s:last_test)
    return
  endif

  let test_type = s:last_test['type']

  if test_type ==# 'test-var'
    let query = s:last_test['query']
    call s:echo_testing_message(query)
    call iced#nrepl#op#cider#test_var_query(query, funcref('s:clojure_test_out'))
  elseif test_type ==# 'retest'
    call iced#nrepl#test#redo()
  elseif test_type ==# 'spec-check'
    let num_tests = s:last_test['num_tests']
    let var_info = s:last_test['var_info']
    call s:run_spec_check_by_current_var(num_tests, var_info)
  endif
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo
" vim:fdm=marker:fdl=0
