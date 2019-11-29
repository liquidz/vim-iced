let s:suite = themis#suite('iced.nrepl.op.cider')
let s:assert = themis#helper('assert')
let s:buf = themis#helper('iced_buffer')
let s:ch = themis#helper('iced_channel')

let s:callback = {'result': ''}
function! s:callback.run(result) abort
  let self.result = a:result
endfunction

let s:default_ns = 'foo.core'
function! s:relay(msg) abort
  if a:msg['op'] ==# 'eval'
    return {'status': ['done'], 'value': printf('#namespace[%s]', s:default_ns)}
  endif
  return {'status': ['done'], 'message': a:msg}
endfunction

function! s:setup() abort
  call iced#nrepl#set_session('clj', 'clj-session')
  call iced#nrepl#change_current_session('clj')
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:relay')})
  call s:buf.start_dummy([printf('(ns %s)', s:default_ns)])
endfunction

function! s:teardown() abort
  call s:buf.stop_dummy()
endfunction

function! s:suite.info_test() abort
  call s:setup()
  call iced#nrepl#op#cider#info('foo.core', 'bar-sym', {v -> s:callback.run(v)})
  call s:assert.equals(s:callback.result['message'], {
        \ 'session': 'clj-session',
        \ 'ns': 'foo.core',
        \ 'symbol': 'bar-sym',
        \ 'op': 'info'})
  call s:teardown()
endfunction

function! s:suite.ns_path_test() abort
  call s:setup()
  call iced#nrepl#op#cider#ns_path('foo.core', {v -> s:callback.run(v)})
  call s:assert.equals(s:callback.result['message'], {
        \ 'session': 'clj-session',
        \ 'ns': 'foo.core',
        \ 'op': 'ns-path'})
  call s:teardown()
endfunction

function! s:suite.ns_list_test() abort
  call s:setup()
  call iced#nrepl#op#cider#ns_list({v -> s:callback.run(v)})
  call s:assert.equals(s:callback.result['message'], {
        \ 'session': 'clj-session',
        \ 'op': 'ns-list'})
  call s:teardown()
endfunction

function! s:suite.ns_load_all_test() abort
  call s:setup()
  call iced#nrepl#op#cider#ns_load_all({v -> s:callback.run(v)})
  call s:assert.equals(s:callback.result['message'], {
        \ 'session': 'clj-session',
        \ 'op': 'ns-load-all'})
  call s:teardown()
endfunction

function! s:suite.retest_test() abort
  call s:setup()
  call iced#nrepl#op#cider#retest({v -> s:callback.run(v)})
  call s:assert.equals(type(s:callback.result), v:t_list)
  call s:assert.equals(len(s:callback.result), 1)
  let id = s:callback.result[0]['message']['id']
  call s:assert.equals(type(id), v:t_number)
  call s:assert.equals(s:callback.result[0]['message'], {
        \ 'session': 'clj-session',
        \ 'id': id,
        \ 'op': 'retest'})
  call s:teardown()
endfunction

function! s:suite.undef_test() abort
  call s:setup()
  call iced#nrepl#op#cider#undef('bar-sym', {v -> s:callback.run(v)})
  call s:assert.equals(s:callback.result['message'], {
        \ 'session': 'clj-session',
        \ 'ns': s:default_ns,
        \ 'symbol': 'bar-sym',
        \ 'op': 'undef'})
  call s:teardown()
endfunction

function! s:suite.macroexpand_1_test() abort
  call s:setup()
  call iced#nrepl#op#cider#macroexpand_1('(foo bar)', {v -> s:callback.run(v)})

  let id = s:callback.result['message']['id']
  call s:assert.equals(type(id), v:t_number)
  call s:assert.equals(s:callback.result['message'], {
        \ 'session': 'clj-session',
        \ 'id': id,
        \ 'ns': s:default_ns,
        \ 'code': '(foo bar)',
        \ 'expander': 'macroexpand-1',
        \ 'op': 'macroexpand'})
  call s:teardown()
endfunction

function! s:suite.macroexpand_all_test() abort
  call s:setup()
  call iced#nrepl#op#cider#macroexpand_all('(foo bar)', {v -> s:callback.run(v)})

  let id = s:callback.result['message']['id']
  call s:assert.equals(type(id), v:t_number)
  call s:assert.equals(s:callback.result['message'], {
        \ 'session': 'clj-session',
        \ 'id': id,
        \ 'ns': s:default_ns,
        \ 'code': '(foo bar)',
        \ 'expander': 'macroexpand-all',
        \ 'op': 'macroexpand'})
  call s:teardown()
endfunction

function! s:suite.toggle_trace_ns_test() abort
  call s:setup()
  call iced#nrepl#op#cider#toggle_trace_ns('foo.core', {v -> s:callback.run(v)})
  call s:assert.equals(s:callback.result['message'], {
        \ 'session': 'clj-session',
        \ 'ns': 'foo.core',
        \ 'op': 'toggle-trace-ns'})
  call s:teardown()
endfunction

function! s:suite.toggle_trace_var_test() abort
  call s:setup()
  call iced#nrepl#op#cider#toggle_trace_var('foo.core', 'bar-sym', {v -> s:callback.run(v)})
  call s:assert.equals(s:callback.result['message'], {
        \ 'session': 'clj-session',
        \ 'ns': 'foo.core',
        \ 'sym': 'bar-sym',
        \ 'op': 'toggle-trace-var'})
  call s:teardown()
endfunction

function! s:suite.spec_list_test() abort
  call s:setup()
  call iced#nrepl#op#cider#spec_list({v -> s:callback.run(v)})
  call s:assert.equals(s:callback.result['message'], {
        \ 'session': 'clj-session',
        \ 'op': 'spec-list'})
  call s:teardown()
endfunction

function! s:suite.spec_form_test() abort
  call s:setup()
  call iced#nrepl#op#cider#spec_form('spec-name', {v -> s:callback.run(v)})
  call s:assert.equals(s:callback.result['message'], {
        \ 'session': 'clj-session',
        \ 'spec-name': 'spec-name',
        \ 'op': 'spec-form'})
  call s:teardown()
endfunction
