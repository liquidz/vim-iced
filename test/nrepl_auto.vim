let s:suite = themis#suite('iced.nrepl.auto')
let s:assert = themis#helper('assert')
let s:ch = themis#helper('iced_channel')

let s:clj_tempfile = printf('%s.clj', tempname())
let s:cljs_tempfile = printf('%s.cljs', tempname())

let s:test = {'messages': {}} " {{{
function! s:test.relay(msg) abort
  call add(self.messages, a:msg)
  return {'status': ['done']}
endfunction

function! s:test.get_messages() abort
  return self.messages
endfunction

function! s:test.clear_messages() abort
  let self['messages'] = []
endfunction
" }}}

function! s:setup(edit_file) abort " {{{
  call writefile(['(ns clj.foo)'], s:clj_tempfile)
  call writefile(['(ns cljs.bar)'], s:cljs_tempfile)

  call iced#nrepl#set_session('clj',  'clj-session')
  call iced#nrepl#set_session('cljs', 'cljs-session')
  call iced#nrepl#set_session('repl', 'repl-session')

  call s:test.clear_messages()
  call s:ch.register_test_builder({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:test.relay(msg)},
        \ })

  if a:edit_file ==# 'cljs'
    exec printf(':sp %s', s:cljs_tempfile)
  else
    exec printf(':sp %s', s:clj_tempfile)
  endif
endfunction " }}}

function! s:teardown() abort " {{{
  exec ':close'
  call delete(s:clj_tempfile)
  call delete(s:cljs_tempfile)
  call iced#nrepl#auto#enable_bufenter(v:false)
endfunction " }}}

function! s:suite.bufenter_in_clj_file_test() abort
  call s:setup('clj')
  call iced#nrepl#change_current_session('clj')
  let g:iced#nrepl#auto#does_switch_session = v:true

  " Disabled bufenter
  call iced#nrepl#auto#enable_bufenter(v:false)
  call s:test.clear_messages()
  call iced#nrepl#auto#bufenter()
  call s:assert.equals(iced#nrepl#current_session(), 'clj-session')
  call s:assert.true(empty(s:test.get_messages()))

  " Enabled bufenter
  call iced#nrepl#auto#enable_bufenter(v:true)
  call s:test.clear_messages()
  call iced#nrepl#auto#bufenter()
  call s:assert.equals(iced#nrepl#current_session(), 'clj-session')
  call s:assert.equals(s:test.get_messages()[0]['code'], '(in-ns ''clj.foo)')

  " Switched session
  call iced#nrepl#change_current_session('cljs')
  call s:test.clear_messages()
  call iced#nrepl#auto#enable_bufenter(v:true)
  call s:assert.equals(iced#nrepl#current_session(), 'cljs-session')
  call iced#nrepl#auto#bufenter()
  call s:assert.equals(iced#nrepl#current_session(), 'clj-session')
  call s:assert.equals(s:test.get_messages()[0]['code'], '(in-ns ''clj.foo)')

  call s:teardown()
  let g:iced#nrepl#auto#does_switch_session = v:false
endfunction

function! s:suite.bufenter_in_cljs_file_test() abort
  call s:setup('cljs')
  call iced#nrepl#change_current_session('cljs')
  let g:iced#nrepl#auto#does_switch_session = v:true

  call iced#nrepl#auto#enable_bufenter(v:true)
  call s:test.clear_messages()
  call iced#nrepl#auto#bufenter()
  call s:assert.equals(iced#nrepl#current_session(), 'cljs-session')
  call s:assert.equals(s:test.get_messages()[0]['code'], '(in-ns ''cljs.bar)')

  " Switched session
  call iced#nrepl#change_current_session('clj')
  call s:test.clear_messages()
  call iced#nrepl#auto#enable_bufenter(v:true)
  call s:assert.equals(iced#nrepl#current_session(), 'clj-session')
  call iced#nrepl#auto#bufenter()
  call s:assert.equals(iced#nrepl#current_session(), 'cljs-session')
  call s:assert.equals(s:test.get_messages()[0]['code'], '(in-ns ''cljs.bar)')

  call s:teardown()
  let g:iced#nrepl#auto#does_switch_session = v:false
endfunction

function! s:suite.leave_test() abort
  call s:setup('clj')
  call s:assert.equals(iced#nrepl#is_connected(), v:true)
  call iced#nrepl#auto#leave()
  call s:assert.equals(iced#nrepl#is_connected(), v:false)
  call s:teardown()
endfunction

" vim:fdm=marker:fdl=0
