let s:suite  = themis#suite('iced.nrepl.debug')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:buf = themis#helper('iced_buffer')
let s:io = themis#helper('iced_io')
let s:ch = themis#helper('iced_channel')
let s:ex_cmd = themis#helper('iced_ex_cmd')
let s:popup = themis#helper('iced_popup')
let s:sel = themis#helper('iced_selector')

function! s:suite.start_test() abort
  let g:iced#debug#debugger = 'default'
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
  let g:iced#debug#debugger = 'default'

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

function! s:__browse_tapped_show_list_test_relay(msg) abort
  if a:msg['op'] ==# 'iced-list-tapped'
    return {'status': ['done'], 'tapped': ['foo', 'bar']}
  endif
  return {'status': ['done']}
endfunction

function! s:suite.browse_tapped_show_list_test() abort
  call s:sel.mock()
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:__browse_tapped_show_list_test_relay')})

  let p = iced#nrepl#debug#browse_tapped('')
  call iced#promise#wait(p)

  let config = s:sel.get_last_config()
  call s:assert.equals(config['candidates'], ['0: foo', '1: bar'])
endfunction


function! s:__browse_tapped_data_test_relay(msg) abort
  if a:msg['op'] ==# 'iced-browse-tapped'
    return {'status': ['done'], 'value': "hello\nworld"}
  endif

  return {'status': ['done']}
endfunction

function! s:suite.browse_tapped_data_test() abort
  call s:io.mock()
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:__browse_tapped_data_test_relay')})
  let info = iced#buffer#document#init()

  call s:assert.false(iced#buffer#document#is_visible())

  let p = iced#nrepl#debug#browse_tapped('foo bar')
  call iced#promise#wait(p)

  call s:assert.true(iced#buffer#document#is_visible())
  call iced#buffer#document#close()

  call s:assert.equals(getbufline(info['bufnr'], 1, '$'), ['hello', 'world'])
  call s:assert.equals(s:io.get_last_args()['feedkeys'],
        \ {'keys': ':IcedBrowseTapped foo bar ', 'mode': 'n'})
endfunction
