let s:suite = themis#suite('iced.nrepl.cljs')
let s:assert = themis#helper('assert')
let s:ch = themis#helper('iced_channel')

function! s:clj_session_fixture() abort
  call iced#nrepl#set_session('clj',  'original-clj-session')
  call iced#nrepl#set_session('cljs', '')
  call iced#nrepl#change_current_session('clj')
endfunction

function! s:cljs_session_fixture() abort
  call iced#nrepl#set_session('clj',  'original-clj-session')
  call iced#nrepl#set_session('cljs', 'original-cljs-session')
  call iced#nrepl#change_current_session('cljs')
endfunction

function! s:suite.check_switching_session_switch_to_cljs_test() abort
  call s:clj_session_fixture()
  let g:iced#eval#inside_comment = v:true

  let test = {'session_patterns': ['new-clj-session']}
  function! test.relay(msg) abort
    let op = a:msg['op']
    if op ==# 'clone'
      return {'status': ['done'], 'new-session': remove(self.session_patterns, 0)}
    endif
    return {'status': ['done']}
  endfunction

  call s:ch.mock({'status_value': 'open', 'relay': {msg -> test.relay(msg)}})

  call s:assert.equals(iced#nrepl#current_session_key(), 'clj')
  let p = iced#nrepl#cljs#check_switching_session({
       \ 'ns': 'cljs.user',
       \ 'session': 'original-clj-session',
       \ }, '')
  let [res, _] = iced#promise#wait(p)

  call s:assert.equals(iced#nrepl#current_session_key(), 'cljs')
  call s:assert.equals(iced#nrepl#current_session(), 'original-clj-session')
  call s:assert.equals(iced#nrepl#clj_session(), 'new-clj-session')
endfunction

function! s:suite.check_switching_session_switch_to_clj_test() abort
  call s:cljs_session_fixture()
  call s:ch.mock({
        \ 'status_value': 'open',
        \ 'relay': {msg -> {'status': ['done']}}})

  call s:assert.equals(iced#nrepl#current_session_key(), 'cljs')
  let p = iced#nrepl#cljs#check_switching_session({
       \ 'ns': 'foo.bar',
       \ 'session': 'original-cljs-session'}, ':cljs/quit')
  let [res, _] = iced#promise#wait(p)

  call s:assert.true(empty(res))
  call s:assert.equals(iced#nrepl#current_session_key(), 'clj')
  call s:assert.equals(iced#nrepl#current_session(), 'original-clj-session')
  call s:assert.equals(iced#nrepl#clj_session(), 'original-clj-session')
  call s:assert.equals(iced#nrepl#cljs_session(), '')
endfunction

function! s:suite.check_switching_session_do_not_switch_test() abort
  "" clj session && session is not 'clj'
  call s:clj_session_fixture()
  call iced#nrepl#change_current_session('clj')
  call s:assert.equals(iced#nrepl#current_session_key(), 'clj')
  let p = iced#nrepl#cljs#check_switching_session({
      \ 'ns': 'cljs.user',
      \ 'session': 'not-clj-session'}, '')
  let [res, _] = iced#promise#wait(p)

  call s:assert.true(empty(res))
  call s:assert.equals(iced#nrepl#current_session_key(), 'clj')

  "" clj session && ns is not cljs.user
  call s:clj_session_fixture()
  call iced#nrepl#change_current_session('clj')
  call s:assert.equals(iced#nrepl#current_session_key(), 'clj')
  let p = iced#nrepl#cljs#check_switching_session({
     \ 'ns': 'foo.bar',
     \ 'session': 'original-clj-session'}, '')
  let [res, _] = iced#promise#wait(p)

  call s:assert.true(empty(res))
  call s:assert.equals(iced#nrepl#current_session_key(), 'clj')

  "" cljs session && session is not 'cljs'
  call s:cljs_session_fixture()
  call s:assert.equals(iced#nrepl#current_session_key(), 'cljs')
  let p = iced#nrepl#cljs#check_switching_session({
     \ 'ns': 'foo.bar',
     \ 'session': 'original-clj-session'}, '')
  let [res, _] = iced#promise#wait(p)

  call s:assert.true(empty(res))
  call s:assert.equals(iced#nrepl#current_session_key(), 'cljs')

  "" cljs session && evaluated code is not `:cljs/quit`
  call s:cljs_session_fixture()
  call s:assert.equals(iced#nrepl#current_session_key(), 'cljs')
  let p = iced#nrepl#cljs#check_switching_session({
     \ 'ns': 'cljs.user',
     \ 'session': 'original-cljs-session'}, ':foo/bar')
  let [res, _] = iced#promise#wait(p)

  call s:assert.true(empty(res))
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
