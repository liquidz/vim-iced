let s:suite  = themis#suite('iced.sign')
let s:assert = themis#helper('assert')

function! s:test_sign_builder() abort
  let test = {}
  function! test.place(id, lnum, name, file) abort
    return ''
  endfunction

  function! test.unplace(id) abort
    return ''
  endfunction

  function! test.unplace_all() abort
    return ''
  endfunction

  return test
endfunction

function! s:suite.place_test() abort
  call iced#di#register('sign', {_ -> s:test_sign_builder()})
  call iced#sign#unplace_all()
  let file = '/path/to/file'

  let id = iced#sign#place('iced_err', 123, file)
  call s:assert.true(type(id) == type(1))

  let res = iced#sign#list_in_current_buffer(file)
  call s:assert.equals(len(res), 1)
  call s:assert.equals(res[0], {'file': file, 'id': id, 'name': 'iced_err', 'line': 123})
endfunction

function! s:suite.unplace_test() abort
  call iced#di#register('sign', {_ -> s:test_sign_builder()})
  call iced#sign#unplace_all()
  let file = '/path/to/file'

  let id1 = iced#sign#place('iced_err', 123, file)
  let id2 = iced#sign#place('iced_err', 234, file)

  call s:assert.equals(len(iced#sign#list_in_current_buffer(file)), 2)
  call iced#sign#unplace(id1)

  let res = iced#sign#list_in_current_buffer(file)
  call s:assert.equals(len(res), 1)
  call s:assert.equals(res[0], {'file': file, 'id': id2, 'name': 'iced_err', 'line': 234})
endfunction

