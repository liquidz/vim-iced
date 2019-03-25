let s:suite = themis#suite('iced.hook')
let s:assert = themis#helper('assert')
let s:ch = themis#helper('iced_channel')
let s:ex = themis#helper('iced_ex_cmd')

function! s:setup() abort
  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#nrepl#set_session('repl', 'repl-session')
  call iced#nrepl#change_current_session('clj')
  call s:ex.register_test_builder()
endfunction

function! s:teardown() abort
  let g:iced#hook = {}
endfunction

function! s:suite.run_shell_type_test() abort
  call s:setup()

  let g:iced#hook = {'shell-test': {'type': 'shell', 'exec': 'simple text'}}
  call iced#hook#run('shell-test', {'foo': 'bar'})
  call s:assert.true(stridx(
        \ get(s:ex.get_last_args(), 'silent_exe', ''),
        \ 'simple text') > 0)

  let g:iced#hook = {'shell-test': {'type': 'shell', 'exec': {v -> printf('shell-test [%s]', v)}}}
  call iced#hook#run('shell-test', {'foo': 'bar'})
  call s:assert.true(stridx(
        \ get(s:ex.get_last_args(), 'silent_exe', ''),
        \ "shell-test [{'foo': 'bar'}]") > 0)

  call s:teardown()
endfunction

function! s:suite.run_eval_type_test() abort
  call s:setup()

  let test = {'last_message': ''}
  function! test.relay(msg) abort
    let self.last_message = a:msg
    return {'status': ['done']}
  endfunction

  call s:ch.register_test_builder({'status_value': 'open', 'relay': {msg -> test.relay(msg)}})

  let g:iced#hook = {'eval-test': {'type': 'eval', 'exec': '(simple form)'}}
  call iced#hook#run('eval-test', 'bar')
  call s:assert.equals(test.last_message['op'], 'eval')
  call s:assert.equals(test.last_message['code'], '(simple form)')
  call s:assert.equals(test.last_message['session'], 'clj-session')

  let g:iced#hook = {'eval-test': {'type': 'eval', 'exec': {v -> printf('(foo %s)', v)}}}
  call iced#hook#run('eval-test', 'bar')
  call s:assert.equals(test.last_message['op'], 'eval')
  call s:assert.equals(test.last_message['code'], '(foo bar)')
  call s:assert.equals(test.last_message['session'], 'clj-session')

  call s:teardown()
endfunction

function! s:suite.run_eval_repl_type_test() abort
  call s:setup()

  let test = {'last_message': ''}
  function! test.relay(msg) abort
    let self.last_message = a:msg
    return {'status': ['done']}
  endfunction

  call s:ch.register_test_builder({'status_value': 'open', 'relay': {msg -> test.relay(msg)}})

  let g:iced#hook = {'eval-repl-test': {'type': 'eval-repl', 'exec': '(simple form)'}}
  call iced#hook#run('eval-repl-test', 'bar')
  call s:assert.equals(test.last_message['op'], 'eval')
  call s:assert.equals(test.last_message['code'], '(simple form)')
  call s:assert.equals(test.last_message['session'], 'repl-session')

  let g:iced#hook = {'eval-repl-test': {'type': 'eval-repl', 'exec': {v -> printf('(foo %s)', v)}}}
  call iced#hook#run('eval-repl-test', 'bar')
  call s:assert.equals(test.last_message['op'], 'eval')
  call s:assert.equals(test.last_message['code'], '(foo bar)')
  call s:assert.equals(test.last_message['session'], 'repl-session')

  call s:teardown()
endfunction

function! s:suite.run_funcion_type_test() abort
  call s:setup()

  let test = {'last_params': ''}
  function! test.exec(params) abort
    let self.last_params = a:params
  endfunction

  let g:iced#hook = {'function-test': {'type': 'function', 'exec': {v -> test.exec(v)}}}
  call iced#hook#run('function-test', {'foo': 'bar'})
  call s:assert.equals(test.last_params, {'foo': 'bar'})

  call s:teardown()
endfunction

function! s:suite.run_unknown_hook_type_test() abort
  call s:setup()

  let g:iced#hook = {'unknown-test': {'type': 'invalid', 'exec': 'invalid evec'}}
  let has_error = v:false
  try
    call iced#hook#run('unknown-test', {'foo': 'bar'})
  catch
    let has_error = v:true
  endtry
  call s:assert.equals(has_error, v:false)

  call s:teardown()
endfunction
