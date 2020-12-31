scriptencoding utf-8

let s:suite  = themis#suite('iced.buffer.stdout')
let s:assert = themis#helper('assert')
let s:holder = themis#helper('iced_holder')
let s:notify = themis#helper('iced_notify')

function! s:suite.open_test() abort
  let info = iced#buffer#stdout#init()

  call s:assert.false(iced#buffer#stdout#is_visible())
  call iced#buffer#stdout#open()
  call s:assert.true(iced#buffer#stdout#is_visible())

  call iced#buffer#stdout#close()
  call s:assert.false(iced#buffer#stdout#is_visible())
endfunction

function! s:suite.append_test() abort
  let nr = iced#buffer#stdout#init()['bufnr']
  call iced#buffer#stdout#clear()

  let init_text_len = len(split(g:iced#buffer#stdout#init_text, '\r\?\n'))
  call s:assert.equals(getbufline(nr, init_text_len + 1, '$'), [])

  call iced#buffer#stdout#append("foo\nbar")
  call s:assert.equals(getbufline(nr, init_text_len + 1, '$'), ['foo', 'bar'])

  call iced#buffer#stdout#append('[32mbaz[m')
  call s:assert.equals(getbufline(nr, init_text_len + 1, '$'), ['foo', 'bar', 'baz'])
endfunction

function! s:suite.append_notify_test() abort
  let g:iced#buffer#stdout#enable_notify = v:true

  call s:notify.mock()
  call iced#buffer#stdout#init()
  call iced#buffer#stdout#close()

  call s:assert.false(iced#buffer#stdout#is_visible())
  call iced#buffer#stdout#append('notified?')
  call s:assert.equals(
       \ {'notify': {'text': 'notified?', 'option': {'title': 'Stdout'}}},
       \ s:notify.get_last_args())

  " not notified when stdout buffer is visible
  call iced#buffer#stdout#open()
  call s:assert.true(iced#buffer#stdout#is_visible())
  call iced#buffer#stdout#append('must not be notified')
  call s:assert.equals(
       \ {'notify': {'text': 'notified?', 'option': {'title': 'Stdout'}}},
       \ s:notify.get_last_args())

  call iced#buffer#stdout#close()
endfunction
