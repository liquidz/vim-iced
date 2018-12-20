let s:suite  = themis#suite('iced.sign')
let s:assert = themis#helper('assert')
let s:buf = themis#helper('iced_buffer')
let s:ex_cmd = themis#helper('iced_ex_cmd')

let s:tempfile = tempname()

function! s:setup() abort " {{{
  call s:ex_cmd.register_test_builder()
  call iced#sign#unplace_all()
  call writefile([''], s:tempfile)
endfunction " }}}

function! s:teardown() abort " {{{
  call delete(s:tempfile)
endfunction " }}}

function! s:suite.place_test() abort
  call s:setup()

  let id = iced#sign#place('iced_error', 123, s:tempfile)
  call s:assert.true(type(id) == type(1))

  let res = iced#sign#list_in_current_buffer(s:tempfile)
  call s:assert.equals(len(res), 1)
  call s:assert.equals(res[0], {'file': s:tempfile, 'id': id, 'name': 'iced_error', 'line': 123})

  call s:teardown()
endfunction

function! s:suite.place_non_existing_file_test() abort
  call s:setup()

  let non_existing_file = tempname()
  let id = iced#sign#place('iced_error', 123, non_existing_file)
  call s:assert.true(empty(id))

  let res = iced#sign#list_in_current_buffer(non_existing_file)
  call s:assert.true(empty(res))

  call s:teardown()
endfunction

function! s:suite.unplace_test() abort
  call s:setup()

  let id1 = iced#sign#place('iced_error', 123, s:tempfile)
  let id2 = iced#sign#place('iced_error', 234, s:tempfile)

  call s:assert.equals(len(iced#sign#list_in_current_buffer(s:tempfile)), 2)
  call iced#sign#unplace(id1)

  let res = iced#sign#list_in_current_buffer(s:tempfile)
  call s:assert.equals(len(res), 1)
  call s:assert.equals(res[0], {'file': s:tempfile, 'id': id2, 'name': 'iced_error', 'line': 234})

  call s:teardown()
endfunction

function! s:suite.unplace_by_name_test() abort
  call s:setup()

  let id1 = iced#sign#place('foo', 123, s:tempfile)
  let id2 = iced#sign#place('bar', 234, s:tempfile)
  let id3 = iced#sign#place('foo', 345, s:tempfile)
  call s:assert.equals(len(iced#sign#list_in_current_buffer(s:tempfile)), 3)

  call iced#sign#unplace_by_name('foo')
  let res = iced#sign#list_in_current_buffer(s:tempfile)
  call s:assert.equals(len(res), 1)
  call s:assert.equals(res[0], {'file': s:tempfile, 'id': id2, 'name': 'bar', 'line': 234})

  call s:teardown()
endfunction

function! s:suite.jump_to_next_test() abort
  call s:setup()
  call s:buf.start_dummy(['', '|', '', ''])

  call iced#sign#place('iced_error', 1, s:tempfile)
  call iced#sign#place('iced_error', 4, s:tempfile)

  call s:assert.equals(line('.'), 2)

  call iced#sign#jump_to_next(s:tempfile)
  call s:assert.equals(line('.'), 4)

  setl wrapscan
  call iced#sign#jump_to_next(s:tempfile)
  call s:assert.equals(line('.'), 1)

  call s:buf.stop_dummy()
  call s:teardown()
endfunction

function! s:suite.jump_to_prev_test() abort
  call s:setup()
  call s:buf.start_dummy(['', '|', '', ''])

  call iced#sign#place('iced_error', 1, s:tempfile)
  call iced#sign#place('iced_error', 4, s:tempfile)

  call s:assert.equals(line('.'), 2)

  call iced#sign#jump_to_prev(s:tempfile)
  call s:assert.equals(line('.'), 1)

  setl wrapscan
  call iced#sign#jump_to_prev(s:tempfile)
  call s:assert.equals(line('.'), 4)

  call s:buf.stop_dummy()
  call s:teardown()
endfunction

" vim:fdm=marker:fdl=0
