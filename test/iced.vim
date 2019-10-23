let s:suite  = themis#suite('iced')
let s:assert = themis#helper('assert')
let s:ch = themis#helper('iced_channel')

function! s:suite.status_test() abort
  call s:ch.mock({'status_value': 'fail'})
  call s:assert.equals(iced#status(), 'not connected')

  call s:ch.mock({'status_value': 'open'})
  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#nrepl#change_current_session('clj')
  call s:assert.equals(iced#status(), 'CLJ')
endfunction

function! s:suite.status_with_cljs_session_test() abort
  call s:ch.mock({'status_value': 'open'})
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

  call s:ch.mock({'status_value': 'open', 'relay': test.relay})
  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#eval_and_read('(+ 1 2 3)')
endfunction

function! s:suite.status_with_lint_op_test() abort
  let test = {}
  function! test.relay(msg) abort
    call s:assert.equals(iced#status(), 'clj repl')
    return {'status': ['done']}
  endfunction

  call s:ch.mock({'status_value': 'open', 'relay': test.relay})
  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#lint#current_file()
endfunction

function! s:suite.eval_and_read_test() abort
  let test = {'response': {}}
  function! test.relay(msg) abort
    return {'status': ['done'], 'value': 6}
  endfunction

  function! test.callback(resp) abort
    let self['response'] = a:resp
  endfunction

  call s:ch.mock({'status_value': 'open', 'relay': test.relay})

  let res = iced#eval_and_read('(+ 1 2 3)')
  call s:assert.equals(res['value'], 6)

  let res = iced#eval_and_read('(+ 1 2 3)', {x -> test.callback(x)})
  call s:assert.equals(res, v:true)
  call s:assert.equals(test.response['value'], 6)
endfunction
