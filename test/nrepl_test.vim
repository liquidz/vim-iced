let s:suite  = themis#suite('iced.nrepl.test')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:buf = themis#helper('iced_buffer')
let s:ch = themis#helper('iced_channel')
let s:qf = themis#helper('iced_quickfix')
let s:ex = themis#helper('iced_ex_cmd')
let s:funcs = s:scope.funcs('autoload/iced/nrepl/test.vim')

let s:tempfile = tempname()

function! s:suite.error_message_test() abort
  call s:assert.equals(
      \ 'foo',
      \ s:funcs.error_message({'var': 'foo'}))

  call s:assert.equals(
      \ 'foo: bar',
      \ s:funcs.error_message({'var': 'foo', 'context': 'bar'}))
endfunction

function! s:suite.summary_success_test() abort
  let dummy_success_resp = {
        \ 'summary': {'test': 1, 'var': 2, 'fail': 0, 'error': 0},
        \ 'testing-ns': 'foo.success'}

  call s:assert.equals(s:funcs.summary(dummy_success_resp),
        \ {'is_success': 1,
        \  'summary': 'foo.success: Ran 1 assertions, in 2 test functions. 0 failures, 0 errors.'})
endfunction

function! s:suite.summary_failure_test() abort
  let dummy_failure_resp = {
        \ 'summary': {'test': 1, 'var': 2, 'fail': 3, 'error': 4},
        \ 'testing-ns': 'foo.failure'}

  call s:assert.equals(s:funcs.summary(dummy_failure_resp),
        \ {'is_success': 0,
        \  'summary': 'foo.failure: Ran 1 assertions, in 2 test functions. 3 failures, 4 errors.'})
endfunction


function! s:ns_path_relay(msg) abort
  return (a:msg['op'] ==# 'ns-path')
        \ ? {'status': ['done'], 'path': '/path/to/file.clj'}
        \ : {}
endfunction

function! s:suite.collect_errors_success_test() abort
  let dummy_resp = [{
        \ 'results': {
        \   'foo.core-test': {
        \     'err-test': [
        \       {'context': [], 'ns': 'foo.core-test', 'message': [], 'type': 'pass', 'var': 'err-test'}]}}}]
  call s:ch.register_test_builder({'status_value': 'open', 'relay': funcref('s:ns_path_relay')})

  call s:assert.equals(s:funcs.collect_errors(dummy_resp), [])
endfunction

function! s:suite.collect_errors_failed_without_diffs_test() abort
  let dummy_resp = [{
        \ 'results': {
        \   'foo.core-test': {
        \     'err-test': [
        \       {'context': [], 'ns': 'foo.core-test', 'message': [], 'type': 'fail', 'var': 'err-test',
        \        'line': 123, 'expected': 'expected-result', 'actual': 'actual-result'}]}}}]
  call s:ch.register_test_builder({'status_value': 'open', 'relay': funcref('s:ns_path_relay')})

  call s:assert.equals(s:funcs.collect_errors(dummy_resp), [
        \ {'type': 'E',
        \  'lnum': 123,
        \  'filename': '/path/to/file.clj',
        \  'expected': 'expected-result',
        \  'actual': 'actual-result',
        \  'text': 'err-test'}])
endfunction

function! s:suite.collect_errors_failed_with_diffs_test() abort
  let dummy_resp = [{
        \ 'results': {
        \   'foo.core-test': {
        \     'err-test': [
        \       {'context': [], 'ns': 'foo.core-test', 'message': [], 'type': 'fail', 'var': 'err-test',
        \        'line': 123, 'expected': 'expected-result',
        \        'diffs': [['actual-result', ['foo', 'bar']]]}]}}}]
  call s:ch.register_test_builder({'status_value': 'open', 'relay': funcref('s:ns_path_relay')})

  call s:assert.equals(s:funcs.collect_errors(dummy_resp), [
        \ {'type': 'E',
        \  'lnum': 123,
        \  'filename': '/path/to/file.clj',
        \  'expected': 'expected-result',
        \  'actual': 'actual-result',
        \  'diffs': "- foo\n+ bar",
        \  'text': 'err-test'}])
endfunction

function! s:suite.collect_errors_errored_test() abort
  let dummy_resp = [{
        \ 'results': {
        \   'foo.core-test': {
        \     'err-test': [
        \       {'context': [], 'ns': 'foo.core-test', 'message': [], 'type': 'error', 'var': 'err-test',
        \        'line': 123, 'expected': 'expected-result', 'error': 'error-message'}]}}}]
  call s:ch.register_test_builder({'status_value': 'open', 'relay': funcref('s:ns_path_relay')})

  call s:assert.equals(s:funcs.collect_errors(dummy_resp), [
        \ {'type': 'E',
        \  'lnum': 123,
        \  'filename': '/path/to/file.clj',
        \  'expected': 'expected-result',
        \  'actual': 'error-message',
        \  'text': 'err-test'}])
endfunction

function! s:suite.collect_errors_could_not_find_ns_path_test() abort
  let dummy_resp = [{
        \ 'results': {
        \   'foo.core-test': {
        \     'err-test': [
        \       {'context': [], 'ns': 'foo.core-test', 'message': [], 'type': 'fail', 'var': 'err-test',
        \        'file': 'test/foo/core_test.clj', 'line': 123, 'expected': 'expected-result', 'actual': 'actual-result'}]}}}]
  call s:ch.register_test_builder({'status_value': 'open', 'relay': {msg ->
        \ (msg['op'] ==# 'ns-path') ? {'status': ['done'], 'path': []} : {}}})
  call iced#cache#set('user-dir', '/user/dir')
  call iced#cache#set('file-separator', '/')

  call s:assert.equals(s:funcs.collect_errors(dummy_resp), [
        \ {'type': 'E',
        \  'lnum': 123,
        \  'filename': '/user/dir/test/foo/core_test.clj',
        \  'expected': 'expected-result',
        \  'actual': 'actual-result',
        \  'text': 'err-test'}])
endfunction

function! s:suite.test_vars_by_ns_name_test() abort
  let test_vars = {'foo': {}, 'bar': {'test': ''}, 'baz': {'test': 'test'}}
  call s:ch.register_test_builder({
        \ 'status_value': 'open',
        \ 'relay': {msg -> (msg['op'] ==# 'ns-vars-with-meta')
        \           ? {'status': ['done'], 'ns-vars-with-meta': test_vars}
        \           : {'status': ['done']}}})

  let ret = iced#nrepl#test#test_vars_by_ns_name('foo.core')
  call s:assert.equals(copy(sort(ret)), ['bar', 'baz'])
endfunction

function! s:suite.test_vars_by_ns_name_error_test() abort
  call s:ch.register_test_builder({
        \ 'status_value': 'open',
        \ 'relay': {msg -> {'status': ['done']}}})

  let ret = iced#nrepl#test#test_vars_by_ns_name('foo.core')
  call s:assert.true(empty(ret))
endfunction

function! s:suite.fetch_test_vars_by_function_under_cursor_test() abort
  let test = {}
  function! test.relay(msg) abort
    if a:msg['op'] ==# 'eval'
      return {'status': ['done'], 'value': '#''foo.bar/baz'}
    elseif a:msg['op'] ==# 'ns-vars-with-meta'
      return {'status': ['done'], 'ns-vars-with-meta': {
            \   'foo-test': {'test': ''},
            \   'bar-test': {'test': ''},
            \   'baz-test': {'test': ''},
            \   'baz-test-fn': {}}}
    else
      return {'status': ['done']}
    endif
  endfunction

  function! test.result_callback(var_name, test_vars) abort
    let self.result = {'var_name': a:var_name, 'test_vars': a:test_vars}
  endfunction

  call s:ch.register_test_builder({'status_value': 'open', 'relay': test.relay})
  call s:buf.start_dummy([
       \ '(ns foo.bar)',
       \ '(defn baz [] "baz" |)'])
  call iced#nrepl#test#fetch_test_vars_by_function_under_cursor('foo.bar', test.result_callback)
  call s:assert.equals(test.result['var_name'], 'baz')
  call s:assert.equals(test.result['test_vars'], ['foo.bar/baz-test'])
  call s:buf.stop_dummy()
endfunction

function! s:run_test_vars_relay(test_results, msg) abort
  let op = a:msg['op']
  if op ==# 'test-var-query'
    return {'status': ['done'],
          \ 'results': {
          \   'dummy.core-test': {
          \     'dummy-test': a:test_results}}}
  elseif op ==# 'ns-path'
    return {'status': ['done'], 'path': s:tempfile}
  endif
  return {'status': ['done']}
endfunction

function! s:suite.run_test_vars_pass_test() abort
  call s:qf.register_test_builder()
  call s:qf.setlist([], 'r')

  let test_results = [
        \ {'context': 'dummy context',
        \  'index': 0,
        \  'ns': 'dummy.core-test',
        \  'message': '',
        \  'type': 'pass',
        \  'var': 'dummy-test'}]

  call s:ch.register_test_builder({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:run_test_vars_relay(test_results, msg)}})
  call s:funcs.run_test_vars('dummy.core-test', ['dummy-test'])
  call s:assert.equals(s:qf.get_last_args()['list'], [])
endfunction

function! s:suite.run_test_vars_fail_test() abort
  call writefile(['foo', 'bar', 'baz'], s:tempfile)
  call s:qf.register_test_builder()
  call s:ex.register_test_builder()
  call s:qf.setlist([], 'r')

  let test_results = [
        \ {'file': s:tempfile,
        \  'context': 'dummy context',
        \  'index': 0,
        \  'expected': "true\n",
        \  'ns': 'dummy.core-test',
        \  'line': 1,
        \  'message': '',
        \  'actual': "false\n",
        \  'type': 'fail',
        \  'var': 'dummy-test'}]

  call s:ch.register_test_builder({
        \ 'status_value': 'open',
        \ 'relay': {msg -> s:run_test_vars_relay(test_results, msg)}})
  call s:funcs.run_test_vars('dummy.core-test', ['dummy-test'])
  call s:assert.equals(s:qf.get_last_args()['list'], [
        \ {'lnum': 1,
        \  'actual': 'false',
        \  'expected': 'true',
        \  'type': 'E',
        \  'text': 'dummy-test: dummy context',
        \  'filename': s:tempfile}
        \ ])

  let exe = s:ex.get_last_args()['exe']
  call s:assert.equals(stridx(exe, ':sign place'), 0)
  call delete(s:tempfile)
endfunction
