let s:suite  = themis#suite('iced.nrepl.debug')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:buf = themis#helper('iced_buffer')
let s:io = themis#helper('iced_io')
let s:ch = themis#helper('iced_channel')
let s:ex_cmd = themis#helper('iced_ex_cmd')
let s:popup = themis#helper('iced_popup')
let s:funcs = s:scope.funcs('autoload/iced/nrepl/debug.vim')

function! s:suite.apply_coordination_test() abort
  call s:buf.start_dummy(['|(aaa (bbb (ccc) ddd) eee)'])

  " aaa
  call cursor(1, 1)
  call s:funcs.apply_coordination([0])
  call s:assert.equals(col('.'), 2)

  " bbb
  call cursor(1, 1)
  call s:funcs.apply_coordination([1])
  call s:assert.equals(col('.'), 6)

  " ccc
  call cursor(1, 1)
  call s:funcs.apply_coordination([1, 1])
  call s:assert.equals(col('.'), 11)

  " ddd
  call cursor(1, 1)
  call s:funcs.apply_coordination([1, 2])
  call s:assert.equals(col('.'), 17)

  " eee
  call cursor(1, 1)
  call s:funcs.apply_coordination([0, 2])
  call s:assert.equals(col('.'), 22)

  call s:buf.stop_dummy()
endfunction

function! s:suite.ensure_dict_test() abort
  call s:assert.equals(
        \ s:funcs.ensure_dict({'foo': 'bar'}),
        \ {'foo': 'bar'})

  call s:assert.equals(
        \ s:funcs.ensure_dict([{'foo': 'bar'}, {'bar': 'baz'}]),
        \ {'foo': 'bar', 'bar': 'baz'})

  call s:assert.equals(s:funcs.ensure_dict('string'), {})
  call s:assert.equals(s:funcs.ensure_dict(123), {})
endfunction

function! s:suite.start_test() abort
  let test = {'last_msg': {}}
  function! test.relay(msg) abort
    let self.last_msg = a:msg
    return {'status': ['done']}
  endfunction

  function! test.get_last_msg() abort
    return self.last_msg
  endfunction

  call s:buf.start_dummy(['|(aaa (bbb (ccc) ddd) eee)'])
  call s:ex_cmd.mock()
  call s:io.mock({'input': 'dummy-input'})
  call s:popup.mock()
  call s:ch.mock({
        \ 'status_value': 'open',
        \ 'relay': {msg -> test.relay(msg)}})

  call iced#nrepl#set_session('clj', 'clj-session')
  call iced#nrepl#change_current_session('clj')

  call s:assert.equals(s:popup.is_opening(), v:false)

  call iced#nrepl#debug#start({
        \ 'key': 123,
        \ 'file': '/path/to/debug',
        \ 'line': 1,
        \ 'column': 1,
        \ 'coor': [1],
        \ 'debug-value': 'foo',
        \ 'locals': [['a', 1], ['bb', 2], ['ccc', 3]],
        \ 'input-type': '',
        \ 'prompt': 'bar',
        \ })

  call s:assert.equals(col('.'), 6+1)
  call s:assert.equals(s:ex_cmd.get_last_args(), {
        \ 'silent_exe': ':edit /path/to/debug'})
  call s:assert.equals(test.get_last_msg(), {
        \ 'key': 123,
        \ 'session': 'clj-session',
        \ 'op': 'debug-input',
        \ 'input': 'dummy-input'})
  call s:assert.equals(s:popup.is_opening(), v:true)
  call s:assert.equals(s:popup.get_last_texts(), [
        \ ' ::value foo',
        \ ' ::locals',
        \ '     a: 1',
        \ '    bb: 2',
        \ '   ccc: 3'])

  call iced#nrepl#debug#quit()
  call s:buf.stop_dummy()
endfunction

function! s:suite.quit_test() abort
  call s:buf.start_dummy(['(aaa (bbb (ccc) ddd) eee)|'])
  call s:ex_cmd.mock()
  call s:io.mock({'input': 'dummy-input'})
  call s:popup.mock()
  call s:ch.mock({
        \ 'status_value': 'open',
        \ 'relay': {_ -> {'status': ['done']}}})

  let expected_col = len(getline('.'))
  call s:assert.equals(col('.'), expected_col)

  call iced#nrepl#debug#start({
        \ 'key': 123,
        \ 'file': '/path/to/debug',
        \ 'line': 1,
        \ 'column': 1,
        \ 'coor': [1],
        \ 'debug-value': 'foo',
        \ 'locals': [['a', 1], ['bb', 2], ['ccc', 3]],
        \ 'input-type': '',
        \ 'prompt': 'bar',
        \ })

  call s:assert.equals(col('.'), 6+1)
  call s:assert.equals(s:popup.is_opening(), v:true)

  call iced#nrepl#debug#quit()

  call s:assert.equals(col('.'), expected_col)
  call s:assert.equals(s:popup.is_opening(), v:false)

  call s:buf.stop_dummy()
endfunction
