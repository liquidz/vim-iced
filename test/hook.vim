let s:suite = themis#suite('iced.hook')
let s:assert = themis#helper('assert')
let s:ch = themis#helper('iced_channel')
let s:ex = themis#helper('iced_ex_cmd')
let s:job = themis#helper('iced_job')
let s:holder = themis#helper('iced_holder')
let s:vt = themis#helper('iced_virtual_text')

function! s:setup() abort
  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#nrepl#change_current_session('clj')
  call s:ex.mock()
  call s:job.mock()
  call s:holder.clear()
  call s:vt.mock()
  let g:iced#eval#inside_comment = v:true
endfunction

function! s:teardown() abort
  let g:iced#hook = {}
  call s:holder.clear()
endfunction

function! s:suite.run_shell_type_test() abort
  call s:setup()

  let g:iced#hook = {'shell-test': {'type': 'shell', 'exec': 'simple text'}}
  call iced#hook#run('shell-test', {'foo': 'bar'})
  call s:assert.equals('simple text', s:job.get_last_command())

  let g:iced#hook = {'shell-test': {'type': 'shell', 'exec': {v -> printf('shell-test [%s]', v)}}}
  call iced#hook#run('shell-test', {'foo': 'bar'})
  call s:assert.equals("shell-test [{'foo': 'bar'}]", s:job.get_last_command())

  call s:teardown()
endfunction

function! s:suite.run_eval_type_test() abort
  call s:setup()
  call s:ch.mock({'status_value': 'open', 'relay': {resp -> s:holder.relay(resp)}})

  let g:iced#hook = {'eval-test': {'type': 'eval', 'exec': '(simple form)'}}
  let p = iced#hook#run('eval-test', 'bar')
  call iced#promise#wait(p)

  let msg = s:holder.get_args()[-1]
  call s:assert.equals(msg['op'], 'eval')
  call s:assert.equals(msg['code'], '(simple form)')
  call s:assert.equals(msg['session'], 'clj-session')

  let g:iced#hook = {'eval-test': {'type': 'eval', 'exec': {v -> printf('(foo %s)', v)}}}
  let p = iced#hook#run('eval-test', 'bar')
  call iced#promise#wait(p)

  let msg = s:holder.get_args()[-1]
  call s:assert.equals(msg['op'], 'eval')
  call s:assert.equals(msg['code'], '(foo bar)')
  call s:assert.equals(msg['session'], 'clj-session')

  call s:teardown()
endfunction

function! s:suite.run_funcion_type_test() abort
  call s:setup()

  let g:iced#hook = {'function-test': {'type': 'function', 'exec': {v -> s:holder.run(v)}}}
  call iced#hook#run('function-test', {'foo': 'bar'})

  let param = s:holder.get_args()[-1]
  call s:assert.equals(param, [{'foo': 'bar'}])

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
