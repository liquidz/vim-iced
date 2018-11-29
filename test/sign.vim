let s:suite  = themis#suite('iced.sign')
let s:assert = themis#helper('assert')

let s:tempfile = tempname()

function! s:setup() abort " {{{
  let test_sign = {}
  function! test_sign.place(id, lnum, name, file) abort
    return ''
  endfunction

  function! test_sign.unplace(id) abort
    return ''
  endfunction

  function! test_sign.unplace_all() abort
    return ''
  endfunction

  call iced#di#register('sign', {_ -> test_sign})
  call iced#sign#unplace_all()
  call writefile([''], s:tempfile)
endfunction " }}}

function! s:teardown() abort " {{{
  call delete(s:tempfile)
endfunction " }}}

function! s:suite.place_test() abort
  call s:setup()

  let id = iced#sign#place('iced_err', 123, s:tempfile)
  call s:assert.true(type(id) == type(1))

  let res = iced#sign#list_in_current_buffer(s:tempfile)
  call s:assert.equals(len(res), 1)
  call s:assert.equals(res[0], {'file': s:tempfile, 'id': id, 'name': 'iced_err', 'line': 123})

  call s:teardown()
endfunction

function! s:suite.place_non_existing_file_test() abort
  call s:setup()

  let non_existing_file = tempname()
  let id = iced#sign#place('iced_err', 123, non_existing_file)
  call s:assert.true(empty(id))

  let res = iced#sign#list_in_current_buffer(non_existing_file)
  call s:assert.true(empty(res))

  call s:teardown()
endfunction

function! s:suite.unplace_test() abort
  call s:setup()

  let id1 = iced#sign#place('iced_err', 123, s:tempfile)
  let id2 = iced#sign#place('iced_err', 234, s:tempfile)

  call s:assert.equals(len(iced#sign#list_in_current_buffer(s:tempfile)), 2)
  call iced#sign#unplace(id1)

  let res = iced#sign#list_in_current_buffer(s:tempfile)
  call s:assert.equals(len(res), 1)
  call s:assert.equals(res[0], {'file': s:tempfile, 'id': id2, 'name': 'iced_err', 'line': 234})

  call s:teardown()
endfunction

" vim:fdm=marker:fdl=0
