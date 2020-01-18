let s:suite  = themis#suite('iced.buffer')
let s:assert = themis#helper('assert')
let s:holder = themis#helper('iced_holder')

let s:bufname = 'iced_buffer_test'

function! s:init_buf() abort
  call s:holder.clear()
  let info = iced#buffer#init(s:bufname, s:holder.run)
  let nr = info['bufnr']
  call setbufvar(nr, '&bufhidden', 'hide')
  call setbufvar(nr, '&buflisted', 0)
  call setbufvar(nr, '&buftype', 'nofile')
  call setbufvar(nr, '&swapfile', 0)

  return info
endfunction

function! s:suite.init_test() abort
  call s:holder.clear()
  let info = s:init_buf()

  call s:assert.equals(type(info['bufnr']), v:t_number)
  call s:assert.equals(info['bufname'], s:bufname)
  call s:assert.true(info['loaded'])
  call s:assert.equals(s:holder.get_args(), [[info['bufnr']]])

  call s:assert.equals(iced#buffer#nr(s:bufname), info['bufnr'])
endfunction

function! s:suite.set_var_test() abort
  let nr = iced#buffer#init(s:bufname)['bufnr']
  call setbufvar(nr, 'buffer_test_var', '')

  call s:assert.equals(getbufvar(nr, 'buffer_test_var', ''), '')
  call iced#buffer#set_var(s:bufname, 'buffer_test_var', 'hello')
  call s:assert.equals(getbufvar(nr, 'buffer_test_var', ''), 'hello')
endfunction

function! s:suite.open_test() abort
  let nr = s:init_buf()['bufnr']
  call s:assert.false(iced#buffer#is_visible(s:bufname))

  call iced#buffer#open(s:bufname)
  call s:assert.true(iced#buffer#is_visible(s:bufname))

  call iced#buffer#close(s:bufname)
  call s:assert.false(iced#buffer#is_visible(s:bufname))
endfunction

function! s:suite.open_with_scroll_to_bottom_test() abort
  let nr = s:init_buf()['bufnr']
  call iced#buffer#set_contents(s:bufname, "a\nb\nc\nd\ne\nf\ng")

  call iced#buffer#open(s:bufname, {'height': 12})
  call iced#buffer#focus(s:bufname)
  call s:assert.equals(getwininfo(win_getid())[0]['height'], 12)
  call cursor(2, 1)
  call iced#buffer#close(s:bufname)

  call iced#buffer#open(s:bufname)
  call iced#buffer#focus(s:bufname)
  call s:assert.equals(line('.'), 2)

  call iced#buffer#close(s:bufname)
  call iced#buffer#open(s:bufname, {'scroll_to_bottom': v:true})
  call iced#buffer#focus(s:bufname)
  call s:assert.equals(line('.'), 7)

  call iced#buffer#close(s:bufname)
endfunction

function! s:suite.open_with_scroll_to_top_test() abort
  let nr = s:init_buf()['bufnr']
  call iced#buffer#set_contents(s:bufname, "a\nb\nc\nd\ne\nf\ng")

  call iced#buffer#open(s:bufname)
  call iced#buffer#focus(s:bufname)
  call cursor(2, 1)
  call iced#buffer#close(s:bufname)

  call iced#buffer#open(s:bufname)
  call iced#buffer#focus(s:bufname)
  call s:assert.equals(line('.'), 2)

  call iced#buffer#close(s:bufname)
  call iced#buffer#open(s:bufname, {'scroll_to_top': v:true})
  call iced#buffer#focus(s:bufname)
  call s:assert.equals(line('.'), 1)

  call iced#buffer#close(s:bufname)
endfunction

function! s:suite.set_contents_and_clear_test() abort
  let nr = s:init_buf()['bufnr']
  call iced#buffer#set_contents(s:bufname, "a\nb\nc")
  call s:holder.clear()

  call s:assert.equals(getbufline(nr, 1, '$'), ['a', 'b', 'c'])
  call iced#buffer#clear(s:bufname, s:holder.run)
  call s:assert.equals(getbufline(nr, 1, '$'), [''])
  call s:assert.equals(s:holder.get_args(), [[nr]])
endfunction

function! s:suite.append_test() abort
  let nr = s:init_buf()['bufnr']
  call iced#buffer#clear(s:bufname)
  call iced#buffer#open(s:bufname, {'scroll_to_top': v:true})

  call iced#buffer#append(s:bufname, "foo\nbar")
  call s:assert.equals(getbufline(nr, 1, '$'), ['', 'foo', 'bar'])
  call iced#buffer#focus(s:bufname)
  call s:assert.equals(line('.'), 1)

  call iced#buffer#append(s:bufname, 'baz', {'scroll_to_bottom': v:true})
  call s:assert.equals(getbufline(nr, 1, '$'), ['', 'foo', 'bar', 'baz'])
  call iced#buffer#focus(s:bufname)
  call s:assert.equals(line('.'), 4)

  call iced#buffer#close(s:bufname)
endfunction
