let s:suite = themis#suite('iced.nrepl.cljs')
let s:assert = themis#helper('assert')
let s:nrepl = themis#helper('iced_nrepl')

function! s:clj_session_fixture() abort
  call iced#nrepl#set_session('clj',  'original-clj-session')
  call iced#nrepl#set_session('repl', 'original-repl-session')
  call iced#nrepl#set_session('cljs', '')
  call iced#nrepl#set_session('cljs_repl', '')
  call iced#nrepl#change_current_session('clj')
endfunction

function! s:cljs_session_fixture() abort
  call iced#nrepl#set_session('clj',  'original-clj-session')
  call iced#nrepl#set_session('repl', 'original-repl-session')
  call iced#nrepl#set_session('cljs', 'original-cljs-session')
  call iced#nrepl#set_session('cljs_repl', 'original-cljs-repl-session')
  call iced#nrepl#change_current_session('cljs')
endfunction

function! s:suite.check_switching_session_switch_to_cljs_test() abort
  call s:clj_session_fixture()

  let test = {'session_patterns': ['cljs-repl-session', 'new-repl-session']}
  function! test.relay(msg) abort
    let op = a:msg['op']
    if op ==# 'clone'
      return {'status': ['done'], 'new-session': remove(self.session_patterns, 0)}
    endif
    return {'status': ['done']}
  endfunction

  call s:nrepl.start_test_state({'relay': {msg -> test.relay(msg)}})

  call s:assert.equals(iced#nrepl#current_session_key(), 'clj')
  call iced#nrepl#cljs#check_switching_session({
       \ 'ns': 'cljs.user',
       \ 'session': 'original-repl-session',
       \ })

  call s:assert.equals(iced#nrepl#current_session_key(), 'cljs')
  call s:assert.equals(iced#nrepl#current_session(), 'original-repl-session')
  call s:assert.equals(iced#nrepl#clj_session(), 'original-clj-session')
  call s:assert.equals(iced#nrepl#repl_session(), 'new-repl-session')
  call s:assert.equals(iced#nrepl#cljs_repl_session(), 'cljs-repl-session')
endfunction

function! s:suite.check_switching_session_switch_to_clj_test() abort
  call s:cljs_session_fixture()
  call s:nrepl.start_test_state({
        \ 'relay': {msg -> {'status': ['done']}}})

  call s:assert.equals(iced#nrepl#current_session_key(), 'cljs')
  call iced#nrepl#cljs#check_switching_session({
       \ 'ns': 'foo.bar',
       \ 'session': 'original-cljs-repl-session'})
  call s:assert.equals(iced#nrepl#current_session_key(), 'clj')
  call s:assert.equals(iced#nrepl#current_session(), 'original-clj-session')
  call s:assert.equals(iced#nrepl#clj_session(), 'original-clj-session')
  call s:assert.equals(iced#nrepl#repl_session(), 'original-repl-session')
  call s:assert.equals(iced#nrepl#cljs_session(), '')
  call s:assert.equals(iced#nrepl#cljs_repl_session(), '')
endfunction

function! s:suite.check_switching_session_do_not_switch_test() abort
  "" clj session && session is not 'repl'
  call s:clj_session_fixture()
  call iced#nrepl#change_current_session('clj')
  call s:assert.equals(iced#nrepl#current_session_key(), 'clj')
  call iced#nrepl#cljs#check_switching_session({
      \ 'ns': 'cljs.user',
      \ 'session': 'original-clj-session'})
  call s:assert.equals(iced#nrepl#current_session_key(), 'clj')

  "" clj session && ns is not cljs.user
  call s:clj_session_fixture()
  call iced#nrepl#change_current_session('clj')
  call s:assert.equals(iced#nrepl#current_session_key(), 'clj')
  call iced#nrepl#cljs#check_switching_session({
      \ 'ns': 'foo.bar',
      \ 'session': 'original-repl-session'})
  call s:assert.equals(iced#nrepl#current_session_key(), 'clj')

  "" cljs session && session is not 'cljs_repl'
  call s:cljs_session_fixture()
  call s:assert.equals(iced#nrepl#current_session_key(), 'cljs')
  call iced#nrepl#cljs#check_switching_session({
      \ 'ns': 'foo.bar',
      \ 'session': 'original-repl-session'})
  call s:assert.equals(iced#nrepl#current_session_key(), 'cljs')

  "" cljs session && ns is cljs.user
  call s:cljs_session_fixture()
  call s:assert.equals(iced#nrepl#current_session_key(), 'cljs')
  call iced#nrepl#cljs#check_switching_session({
      \ 'ns': 'cljs.user',
      \ 'session': 'original-cljs-repl-session'})
  call s:assert.equals(iced#nrepl#current_session_key(), 'cljs')
endfunction

function! s:suite.cycle_session_test() abort
  call s:cljs_session_fixture()
  call s:assert.equals(iced#nrepl#current_session_key(), 'cljs')
  call iced#nrepl#cljs#cycle_session()
  call s:assert.equals(iced#nrepl#current_session_key(), 'clj')
  call iced#nrepl#cljs#cycle_session()
  call s:assert.equals(iced#nrepl#current_session_key(), 'cljs')
endfunction

function! s:suite.cycle_session_failure_test() abort
  " no cljs session
  call s:clj_session_fixture()
  call s:assert.equals(iced#nrepl#current_session_key(), 'clj')
  call iced#nrepl#cljs#cycle_session()
  call s:assert.equals(iced#nrepl#current_session_key(), 'clj')
endfunction
