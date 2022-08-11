let s:save_cpo = &cpoptions
set cpoptions&vim

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

function! iced#nrepl#eval#err(err, ...) abort
  let opt = get(a:, 1, {})
  let is_verbose = get(opt, 'verbose', v:true)

  let err_info = s:parse_error(a:err)
  if !empty(err_info)
    if is_verbose
      call iced#message#error_str(err_info['text'])
    endif
  else
    if is_verbose
      call iced#message#error_str(a:err)
    endif
  endif
endfunction

" NOTE: Each stacktrace format is like below
"       {'file': 'form-init11159443384990986285.clj',
"        'flags': ['project', 'repl', 'clj'],
"        'ns': 'foo.core',
"        'name': 'foo.core$boom/invokeStatic',
"        'method': 'invokeStatic',
"        'line': 9,
"        'fn': 'boom',
"        'class': 'foo.core$boom',
"        'file-url': 'file:/private/tmp/foo/ src/foo/core.clj',
"        'type': 'clj',
"        'var': 'foo.core/boom'}
function! s:print_stack_trace(resp) abort
  let errors = []

  if type(a:resp) == v:t_list
    for resp in a:resp
      let class = get(resp, 'class', '')
      if empty(class) | continue | endif
      let stacktrace = get(resp, 'stacktrace', [])
      if empty(stacktrace) | continue | endif

      call iced#buffer#stdout#append(class)
      for item in stacktrace
        let name = get(item, 'name')
        let file = get(item, 'file')
        let line = get(item, 'line')
        let text = printf('  at %s(%s:%d)', name, file, line)
        call iced#buffer#stdout#append(text)

        let file_url = get(item, 'file-url')
        let var = get(item, 'var')
        if ! empty(file_url)
          call add(errors, {
                \ 'filename': iced#util#normalize_path(file_url),
                \ 'lnum': line,
                \ 'end_lnum': line,
                \ 'text': (empty(var) ? name : var),
                \ 'type': 'E',
                \ })
        endif
      endfor
    endfor
  endif

  if ! empty(errors)
    call iced#qf#set(errors)
  endif
endfunction

function! iced#nrepl#eval#out(resp, ...) abort
  let opt = get(a:, 1, {})
  if has_key(a:resp, 'value')
    if get(opt, 'verbose', v:true)
      let value = a:resp['value']
      echo iced#util#shorten(value)

      if index(g:iced#eval#values_to_skip_storing_register, value) == -1
        call iced#util#store_and_slide_registers(value)
      endif

      let virtual_text_opt = copy(get(opt, 'virtual_text', {}))
      let virtual_text_opt['highlight'] = g:iced#eval#popup_highlight
      let virtual_text_opt['align'] = g:iced#eval#popup_align

      if g:iced#eval#keep_inline_result
        let virtual_text_opt['auto_clear'] = v:false
      else
        let virtual_text_opt['auto_clear'] = v:true
      endif
      let virtual_text_opt['indent'] = 3 " len('=> ')

      call iced#system#get('virtual_text').set(
            \ printf('=> %s', value),
            \ virtual_text_opt)
    endif
  endif

  if has_key(a:resp, 'ex') && !empty(a:resp['ex'])
    call iced#nrepl#op#cider#stacktrace(funcref('s:print_stack_trace'))
  endif

  call iced#nrepl#eval#err(get(a:resp, 'err', ''), opt)

  call iced#system#get('future').do({-> iced#hook#run('evaluated', {'result': a:resp, 'option': opt})})

  if has_key(opt, 'code')
    return iced#nrepl#cljs#check_switching_session(a:resp, opt.code)
  endif
  return iced#promise#resolve(v:true)
endfunction

function! s:is_comment_form(code) abort
  return (stridx(a:code, '(comment') == 0)
endfunction

function! iced#nrepl#eval#normalize_code(code) abort
  " c.f. autoload/iced/repl.vim
  if g:iced#eval#inside_comment && s:is_comment_form(a:code)
    return substitute(a:code, '^(comment', '(do', '')
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
  let out_opt = copy(opt)
  let out_opt['code'] = code

  let Callback = get(opt, 'callback', {resp -> iced#nrepl#eval#out(resp, out_opt)})
  if has_key(opt, 'callback')
    unlet opt['callback']
  endif

  if !get(opt, 'ignore_ns', v:false)
    let ns_name = iced#nrepl#ns#name_by_buf()
    if !empty(ns_name) && iced#nrepl#ns#is_created()
      let opt['ns'] = ns_name
    endif
  endif

  try
    return iced#promise#call('iced#nrepl#eval', [code, opt])
          \.then(Callback)
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
  if empty(symbol) | return iced#message#error('not_found') | endif

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

  call iced#nrepl#eval('*1', {'use-printer?': v:true}, m.callback)
endfunction

function! iced#nrepl#eval#outer_top_list(...) abort
  if ! iced#nrepl#check_session_validity() | return | endif
  let ret = iced#paredit#get_top_list_in_comment()
  let code = get(ret, 'code')
  if empty(code)
    return iced#message#error('finding_code_error')
  endif

  let pos = ret['curpos']
  let opt = {'line': pos[1], 'column': pos[2]}
  call extend(opt, get(a:, 1, {}))

  " c.f. autoload/iced/repl.vim
  if !empty(g:iced#eval#mark_at_last)
    call setpos(printf("'%s", g:iced#eval#mark_at_last), pos)
  endif

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
  let Fn = iced#repl#get('eval_code')
  if type(Fn) == v:t_func
    return s:eval_visual(Fn)
  endif
endfunction

function! iced#nrepl#eval#clear_inline_result() abort
  call iced#system#get('virtual_text').clear()
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
