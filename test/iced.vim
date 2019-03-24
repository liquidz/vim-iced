let s:suite  = themis#suite('iced')
let s:assert = themis#helper('assert')
let s:nrepl = themis#helper('iced_nrepl')

function! s:suite.status_test() abort
  call s:nrepl.start_test_state({'is_connected': v:false})
  call s:assert.equals(iced#status(), 'not connected')

  call s:nrepl.start_test_state({})
  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#nrepl#change_current_session('clj')
  call s:assert.equals(iced#status(), 'CLJ')
endfunction

function! s:suite.status_with_cljs_session_test() abort
  call s:nrepl.start_test_state({})
  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#nrepl#set_session('cljs',  'cljs-session')
  call iced#nrepl#change_current_session('clj')
  call s:assert.equals(iced#status(), 'CLJ(cljs)')
  call iced#nrepl#change_current_session('cljs')
  call s:assert.equals(iced#status(), 'CLJS(clj)')
endfunction

function! s:suite.status_evaluating_test() abort
  let test = {}
  function! test.relay(msg) abort
    call s:assert.equals(iced#status(), 'evaluating')
    return {'status': ['done']}
  endfunction

  call s:nrepl.start_test_state({'relay': test.relay})
  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#eval_and_read('(+ 1 2 3)')
endfunction

function! s:suite.status_with_lint_op_test() abort
  let test = {}
  function! test.relay(msg) abort
    call s:assert.equals(iced#status(), 'CLJ')
    return {'status': ['done']}
  endfunction

  call s:nrepl.start_test_state({'relay': test.relay})
  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#nrepl#set_session('cljs',  '')
  call iced#nrepl#change_current_session('clj')
  call iced#lint#current_file()
endfunction
