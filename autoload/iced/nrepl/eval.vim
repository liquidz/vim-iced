let s:save_cpo = &cpoptions
set cpoptions&vim

let g:iced#eval#inside_comment = get(g:, 'iced#eval#inside_comment', v:true)

function! s:parse_error(err) abort
  " Clojure 1.9 or above
  let err = matchstr(a:err, ', compiling:(.\+:\d\+:\d\+)')
  if !empty(err)
    let text = trim(substitute(a:err, err, '', ''))
    " 13 = len(', compiling:(')
    let err = err[13:len(err)-2]
    let arr = split(err, ':')

    return {'filename': arr[0], 'lnum': arr[1], 'text': text}
  endif

  " Clojure 1.10 or later
  let err = matchstr(a:err, 'compiling at (.\+:\d\+:\d\+)')
  if !empty(err)
    let idx = stridx(a:err, "\n")
    let text = (idx == -1) ? '' : trim(strpart(a:err, idx))

    " 14 = len('compiling at (')
    let err = err[14:len(err)-2]
    let arr = split(err, ':')
    return {'filename': arr[0], 'lnum': arr[1], 'text': text}
  endif
endfunction

function! iced#nrepl#eval#err(err) abort
  if empty(a:err)
    return iced#qf#clear()
  endif

  let err_info = s:parse_error(a:err)
  if !empty(err_info)
    call iced#qf#set([err_info])
    call iced#message#error_str(err_info['text'])
  else
    call iced#message#error_str(a:err)
  endif
endfunction

function! iced#nrepl#eval#out(resp, ...) abort
  if has_key(a:resp, 'value')
    echo iced#util#shorten(a:resp['value'])

    call iced#system#get('virtual_text').set(
          \ printf('=> %s', a:resp['value']),
          \ {'highlight': 'Comment', 'auto_clear': v:true})
  endif

  if has_key(a:resp, 'ex') && !empty(a:resp['ex'])
    call iced#message#error_str(a:resp['ex'])
  endif

  call iced#nrepl#eval#err(get(a:resp, 'err', ''))

  if has_key(a:, 1)
    call iced#nrepl#cljs#check_switching_session(a:resp, get(a:, 1))
  endif
endfunction

function! s:is_comment_form(code) abort
  return (stridx(a:code, '(comment') == 0)
endfunction

function! s:extract_inside_form(code) abort
  let i = strridx(a:code, ')')
  if i != -1
    " NOTE: 8 = len('(comment')
    return trim(a:code[8:i-1])
  endif
  return a:code
endfunction

function! iced#nrepl#eval#normalize_code(code) abort
  if g:iced#eval#inside_comment && s:is_comment_form(a:code)
    return s:extract_inside_form(a:code)
  endif
  return a:code
endfunction

function! iced#nrepl#eval#code(code, ...) abort
  let opt = get(a:, 1, {})
  if ! get(opt, 'ignore_session_validity', v:false) && ! iced#nrepl#check_session_validity()
    return
  endif
  let view = winsaveview()
  let reg_save = @@

  let code = iced#nrepl#eval#normalize_code(a:code)
  let Callback = get(opt, 'callback', {resp -> iced#nrepl#eval#out(resp, code)})
  if has_key(opt, 'callback')
    unlet opt['callback']
  endif

  try
    return iced#nrepl#ns#require_if_not_loaded_promise()
          \.then({_ -> iced#nrepl#eval(code, Callback, opt)})
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

function! s:undefined(resp, symbol) abort
  if iced#util#has_status(a:resp, 'undef-error')
    if has_key(a:resp, 'pp-stacktrace')
      let first_stacktrace = a:resp['pp-stacktrace'][0]
      call iced#message#error_str(get(first_stacktrace, 'message', 'undef-error'))
    else
      call iced#message#error_str(get(a:resp, 'ex', 'undef-error'))
    endif
  else
    call iced#message#info('undefined', a:symbol)
  endif
endfunction

function! iced#nrepl#eval#undef(symbol) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let symbol = empty(a:symbol) ? iced#nrepl#var#cword() : a:symbol
  call iced#nrepl#op#cider#undef(symbol, {resp -> s:undefined(resp, symbol)})
endfunction

function! s:all_undefined_in_ns(ns, resp) abort
  if has_key(a:resp, 'ex') && !empty(a:resp['ex'])
    call iced#nrepl#eval#out(a:resp)
  else
    call iced#message#info('undefined', a:ns)
  endif
endfunction

function! iced#nrepl#eval#undef_all_in_ns(...) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  let ns = get(a:, 1, '')
  let ns = empty(ns) ? iced#nrepl#ns#name() : ns
  let code = printf('(let [ns-sym ''%s] (doseq [x (keys (ns-interns ns-sym))] (ns-unmap ns-sym x)))', ns)
  return iced#nrepl#eval#code(code, {'callback': funcref('s:all_undefined_in_ns', [ns])})
endfunction

function! iced#nrepl#eval#print_last() abort
  let m = {}
  function! m.callback(resp) abort
    if has_key(a:resp, 'value')
      call iced#buffer#stdout#append(a:resp['value'])
    endif
  endfunction

  call iced#nrepl#eval('*1', m.callback, {'use-printer?': v:true})
endfunction

function! iced#nrepl#eval#outer_top_list() abort
  if ! iced#nrepl#check_session_validity() | return | endif
  let ret = iced#paredit#get_current_top_list()
  let code = ret['code']
  if empty(code)
    return iced#message#error('finding_code_error')
  endif

  let pos = ret['curpos']
  let opt = {'line': pos[1], 'column': pos[2]}
  return iced#nrepl#eval#code(code, opt)
endfunction

function! iced#nrepl#eval#ns() abort
  let ns_code = iced#nrepl#ns#get()
  return iced#nrepl#eval#code(ns_code)
endfunction

function! s:eval_visual(evaluator) abort
  let reg_save = @@
  try
    silent normal! gvy
    return a:evaluator(trim(@@))
  finally
    let @@ = reg_save
  endtry
endfunction

function! iced#nrepl#eval#visual() abort " range
  return s:eval_visual(function('iced#nrepl#eval#code'))
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
