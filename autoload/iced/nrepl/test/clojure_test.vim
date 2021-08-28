let s:save_cpo = &cpoptions
set cpoptions&vim

" ::errors [::error]
"
" ::error
" - req
"   :text
"   :type (E)
" - opt
"   :lnum
"   :filename
"   :expected
"   :actual
"   :diffs
"
" :: summary
" - req
"   :summary String
"   :is_success Bool

function! s:error_message(test) abort
  if has_key(a:test, 'context') && !empty(a:test['context'])
    return printf('%s: %s', a:test['var'], a:test['context'])
  elseif has_key(a:test, 'message') && !empty(a:test['message'])
    return printf('%s: %s', a:test['var'], a:test['message'])
  else
    return a:test['var']
  endif
endfunction

function! s:extract_actual_values(test) abort
  if !has_key(a:test, 'diffs') || type(a:test['diffs']) != v:t_list
    return {'actual': trim(get(a:test, 'actual', ''))}
  endif

  let diffs = a:test['diffs'][0]
  return {
      \ 'actual': trim(diffs[0]),
      \ 'diffs': printf("- %s\n+ %s", trim(diffs[1][0]), trim(diffs[1][1])),
      \ }
endfunction

function! s:collect_errors_and_passes(resp) abort
  let errors  = []
  let passes = []

  let is_ns_path_op_supported = iced#nrepl#is_supported_op('ns-path')

  for response in iced#util#ensure_array(a:resp)
    let results = get(response, 'results', {})

    for ns_name in keys(results)
      let ns_results = results[ns_name]

      for test_name in keys(ns_results)
        let test_results = ns_results[test_name]

        for test in test_results
          if test['type'] !=# 'fail' && test['type'] !=# 'error'
            call add(passes, {'var': get(test, 'var', '')})
            continue
          endif

          let filename = get(test, 'file')
          if !filereadable(filename) && is_ns_path_op_supported
            let ns_path_resp = iced#nrepl#op#cider#sync#ns_path(ns_name)

            if type(ns_path_resp) != v:t_dict || !has_key(ns_path_resp, 'path')
              continue
            endif

            if empty(ns_path_resp['path'])
              if !has_key(test, 'file') || type(test['file']) != v:t_string
                continue
              endif
              let filename = printf('%s%s%s',
                    \ iced#nrepl#system#user_dir(),
                    \ iced#nrepl#system#separator(),
                    \ test['file'])
            else
              let filename = ns_path_resp['path']
            endif
          endif

          let err = {
                  \ 'filename': filename,
                  \ 'text': s:error_message(test),
                  \ 'expected': trim(get(test, 'expected', '')),
                  \ 'type': 'E',
                  \ 'var': get(test, 'var', ''),
                  \ }
          if has_key(test, 'line') && type(test['line']) == v:t_number
            let err['lnum'] = test['line']
          endif

          if test['type'] ==# 'fail'
            call add(errors, extend(copy(err), s:extract_actual_values(test)))
          elseif test['type'] ==# 'error'
            call add(errors, extend(copy(err), {'actual': get(test, 'error', get(test, 'actual', ''))}))
          endif
        endfor
      endfor
    endfor
  endfor

  return [errors, passes]
endfunction

function! s:summary(resp) abort
  for resp in iced#util#ensure_array(a:resp)
    if has_key(resp, 'summary')
      let summary = resp['summary']

      if summary['test'] == 0
        return {
              \ 'summary': iced#message#get('no_test_summary'),
              \ 'is_success': 1,
              \ }
      else
        return {
              \ 'summary': iced#message#get('test_summary',
              \              get(resp, 'testing-ns', ''),
              \              summary['test'], summary['var'],
              \              summary['fail'], summary['error']),
              \ 'is_success': ((summary['fail'] + summary['error']) == 0),
              \ }
      endif
    endif
  endfor

  return ''
endfunction

function! iced#nrepl#test#clojure_test#parse(resp) abort
  if iced#util#has_status(a:resp, 'namespace-not-found')
    return iced#message#error('not_found')
  endif

  let [errors, passes] = s:collect_errors_and_passes(a:resp)
  return {
        \ 'errors': errors,
        \ 'passes': passes,
        \ 'summary': s:summary(a:resp),
        \ }
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
