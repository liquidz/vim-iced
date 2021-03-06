let s:save_cpo = &cpo
set cpo&vim

let g:iced#hook = get(g:, 'iced#hook', {})

function! s:extract_string(exec, params) abort
  return (type(a:exec) == v:t_func)
        \ ? a:exec(a:params)
        \ : a:exec
endfunction

function! s:run_by_shell(exec, params) abort
  let cmdstr = s:extract_string(a:exec, a:params)
  call iced#system#get('job').start(cmdstr, {})
  return v:true
endfunction

function! s:run_by_evaluating(exec, params) abort
  let code = s:extract_string(a:exec, a:params)
  return iced#nrepl#eval#code(code, {
        \ 'ignore_session_validity': v:true,
        \ })
endfunction

function! s:run_by_function(exec, params) abort
  return (type(a:exec) == v:t_func)
        \ ? a:exec(a:params)
        \ : iced#message#error('invalid_hook_exec', a:exec)
endfunction

function! s:run_by_command(exec) abort
  return iced#system#get('ex_cmd').exe(a:exec)
endfunction

" Returns hooked results as a list
function! iced#hook#run(hook_kind, params, ...) abort
  if !has_key(g:iced#hook, a:hook_kind)
    return [a:params]
  endif

  let opt = get(a:, 1, {})
  let shell_available = get(opt, 'shell', v:true)
  let eval_available = get(opt, 'eval', v:true)
  let function_available = get(opt, 'function', v:true)
  let command_available = get(opt, 'command', v:true)

  let hooks = g:iced#hook[a:hook_kind]
  if type(hooks) == v:t_dict
    let hooks = [hooks]
  endif

  let result = []
  for hook in hooks
    if !has_key(hook, 'type') || !has_key(hook, 'exec')
      call iced#message#error('invalid_hook')
      continue
    endif

    let exec_type = hook['type']
    let Exec_body = hook['exec']

    if shell_available && exec_type ==# 'shell'
      let result += [s:run_by_shell(Exec_body, a:params)]
    elseif eval_available && exec_type ==# 'eval'
      let result += [s:run_by_evaluating(Exec_body, a:params)]
    elseif function_available && exec_type ==# 'function'
      let result += [s:run_by_function(Exec_body, a:params)]
    elseif command_available && exec_type ==# 'command'
      let result += [s:run_by_command(Exec_body)]
    else
      call iced#message#error('unknown_hook_type', exec_type)
    endif
  endfor

  return result
endfunction

function! iced#hook#add(hook_kind, definition) abort
  let hook = []
  if has_key(g:iced#hook, a:hook_kind)
    let hook = g:iced#hook[a:hook_kind]
  endif
  if type(hook) != v:t_list
    let hook = [hook]
  endif

  let hook += [a:definition]
  let g:iced#hook[a:hook_kind] = hook
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
