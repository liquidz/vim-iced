let s:suite  = themis#suite('iced.buffer.document')
let s:assert = themis#helper('assert')
let s:holder = themis#helper('iced_holder')

function! s:suite.open_test() abort
  let info = iced#buffer#document#init()

  call s:assert.false(iced#buffer#document#is_visible())
  call iced#buffer#document#open("hello\nworld")
  call s:assert.true(iced#buffer#document#is_visible())

  call s:assert.equals(getbufline(info['bufnr'], 1, '$'), ['hello', 'world'])

  call iced#buffer#document#close()
  call s:assert.false(iced#buffer#document#is_visible())
endfunction

function! s:suite.update_test() abort
  let nr = iced#buffer#document#init()['bufnr']
  call iced#buffer#document#open("hello\nworld")
  call s:assert.equals(getbufline(nr, 1, '$'), ['hello', 'world'])

  call iced#buffer#document#update("foo\nbar")
  call s:assert.equals(getbufline(nr, 1, '$'), ['foo', 'bar'])
endfunction
