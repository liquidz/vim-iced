let s:suite  = themis#suite('iced')
let s:assert = themis#helper('assert')
let s:ch = themis#helper('iced_channel')

function! s:suite.status_test() abort
  call s:ch.register_test_builder({'status_value': 'fail'})
  call s:assert.equals(iced#status(), 'not connected')

  call s:ch.register_test_builder({'status_value': 'open'})
  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#nrepl#change_current_session('clj')
  call s:assert.equals(iced#status(), 'clj repl')
endfunction

function! s:suite.status_evaluating_test() abort
  let test = {}
  function! test.relay(msg) abort
    call s:assert.equals(iced#status(), 'evaluating')
    return {'status': ['done']}
  endfunction

  call s:ch.register_test_builder({'status_value': 'open', 'relay': test.relay})
  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#eval_and_read('(+ 1 2 3)')
endfunction

function! s:suite.status_with_lint_op_test() abort
  let test = {}
  function! test.relay(msg) abort
    call s:assert.equals(iced#status(), 'clj repl')
    return {'status': ['done']}
  endfunction

  call s:ch.register_test_builder({'status_value': 'open', 'relay': test.relay})
  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#lint#current_file()
endfunction
