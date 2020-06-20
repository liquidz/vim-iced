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

function! s:test_var_using_clojure_test_directly(resp) abort
  let var = get(a:resp, 'qualified_var')
  if empty(var) || var ==# 'nil'
    return iced#message#error('not_found')
  endif

  let code = join(readfile(printf('%s/clj/template/run_test_var.clj', g:vim_iced_home)), "\n")
  let code = printf(code, var)

  return iced#promise#call('iced#nrepl#eval', [code])
endfunction

function! iced#nrepl#test#plain#under_cursor() abort
  let current_file = expand('%:p')

  return iced#promise#call('iced#nrepl#var#extract_by_current_top_list', [])
        \.then(funcref('s:test_var_using_clojure_test_directly'))
        \.then(funcref('s:decode_edn'))
        \.then(funcref('s:out', [current_file]))
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
