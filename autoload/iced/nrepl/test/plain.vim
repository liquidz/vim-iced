let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:out(current_file, resp) abort
  let parsed = iced#nrepl#test#clojure_test#parse(a:resp)
  let errs = []
  for err in get(parsed, 'errors', [])
    call add(errs, extend(err, {'filename': a:current_file}))
  endfor
  let parsed['errors'] = errs

  return iced#nrepl#test#done(parsed)
endfunction

function! s:decode_edn(resp) abort
  let value = get(a:resp, 'value', '')
  if empty(value)
    return iced#promise#reject('')
  endif
  return iced#promise#call(iced#system#get('edn').decode, [value])
endfunction

function! s:ignore_keys() abort
  " for babashka.nrepl, line number may be wrong currently
  if has_key(iced#nrepl#version(), 'babashka')
    return ':line'
  endif
  return ''
endfunction

function! s:test_var_using_clojure_test_directly(resp) abort
  let var = get(a:resp, 'qualified_var')
  if empty(var) || var ==# 'nil'
    return iced#message#error('not_found')
  endif

  let vars_code = printf("(list #'%s)", var)
  let code = join(readfile(printf('%s/clj/template/run_test_var.clj', g:vim_iced_home)), "\n")
  let code = printf(code, s:ignore_keys(), vars_code)

  return iced#promise#call('iced#nrepl#eval', [code])
endfunction

function! iced#nrepl#test#plain#under_cursor() abort
  let current_file = expand('%:p')

  return iced#promise#call('iced#nrepl#var#extract_by_current_top_list', [])
        \.then(funcref('s:test_var_using_clojure_test_directly'))
        \.then(funcref('s:decode_edn'))
        \.then(funcref('s:out', [current_file]))
endfunction

function! s:test_ns_using_clojure_test_directly(ns_name) abort
  let vars_code = printf("(vals (ns-interns '%s))", a:ns_name)
  let code = join(readfile(printf('%s/clj/template/run_test_var.clj', g:vim_iced_home)), "\n")
  let code = printf(code, s:ignore_keys(), vars_code)

  return iced#promise#call('iced#nrepl#eval', [code])
endfunction

function! iced#nrepl#test#plain#ns(ns_name) abort
  let current_file = expand('%:p')

  return s:test_ns_using_clojure_test_directly(a:ns_name)
        \.then(funcref('s:decode_edn'))
        \.then(funcref('s:out', [current_file]))
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
