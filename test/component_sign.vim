let s:suite  = themis#suite('iced.component.sign')
let s:assert = themis#helper('assert')

call iced#system#set_component('sign', {
      \ 'start': 'iced#component#sign#start',
      \ 'requires': ['ex_cmd'],
      \ })
let s:sign = iced#system#get('sign')
let s:foo_file = tempname()
let s:bar_file = tempname()

function! s:setup() abort
  call writefile(map(range(10), {_, v -> printf('line%d', v)}), s:foo_file)
  call writefile(map(range(11, 20), {_, v -> printf('line%d', v)}), s:bar_file)

  exec printf(':sp %s', s:foo_file)
  exec printf(':sp %s', s:bar_file)

  call sign_unplace('*')

  call sign_define('iced_dummy1', {'text': 'd1'})
  call sign_define('iced_dummy2', {'text': 'd2'})

  call s:sign.place('iced_dummy1', 3, s:foo_file)
  call s:sign.place('iced_dummy1', 5, s:foo_file, 'group1')
  call s:sign.place('iced_dummy2', 7, s:foo_file)

  call s:sign.place('iced_dummy1', 13, s:bar_file, 'groupN')
  call s:sign.place('iced_dummy1', 15, s:bar_file, 'groupN')
  call s:sign.place('iced_dummy2', 17, s:bar_file, 'groupN')
endfunction

function! s:teardown() abort
  call sign_unplace('*')
  exec printf(':bwipeout %s', s:foo_file)
  exec printf(':bwipeout %s', s:bar_file)

  if filereadable(s:foo_file)
    call delete(s:foo_file)
  endif

  if filereadable(s:bar_file)
    call delete(s:bar_file)
  endif
endfunction

function! s:list_in_buffer() abort
  let list = s:sign.list_in_buffer(s:foo_file)
  call sort(list, {a, b -> a.lnum > b.lnum})
  call map(list, {_, v -> iced#util#select_keys(v, ['lnum', 'id', 'name', 'group'])})
  return list
endfunction

function! s:dissoc(d, k) abort
  let d = copy(a:d)
  unlet d[a:k]
  return d
endfunction

function! s:suite.list_in_buffer_test() abort
  call s:setup()

  let list = s:sign.list_in_buffer(s:foo_file)
  call sort(list, {a, b -> a.lnum > b.lnum})
  call map(list, {_, v -> v['lnum']})
  call s:assert.equals(list, [3, 5, 7])

  let list = s:sign.list_in_buffer(s:bar_file)
  call sort(list, {a, b -> a.lnum > b.lnum})
  call map(list, {_, v -> v['lnum']})
  call s:assert.equals(list, [13, 15, 17])

  call s:teardown()
endfunction

function! s:suite.list_all_test() abort
  call s:setup()

  let list = s:sign.list_all()
  call sort(list, {a, b -> a.lnum > b.lnum})
  call map(list, {_, v -> v['lnum']})
  call s:assert.equals(list, [3, 5, 7, 13, 15, 17])

  call s:teardown()
endfunction

function! s:suite.place_and_list_in_buffer_test() abort
  call s:setup()

  let actual_signs = sign_getplaced(s:foo_file, {'group': '*'})[0]['signs']
  call sort(actual_signs, {a, b -> a.lnum > b.lnum})
  call map(actual_signs, {_, v -> iced#util#select_keys(v, ['lnum', 'id', 'name', 'group'])})

  call s:assert.equals(actual_signs, [
      \ {'lnum': 3, 'id': 1, 'name': 'iced_dummy1', 'group': 'default'},
      \ {'lnum': 5, 'id': 1, 'name': 'iced_dummy1', 'group': 'group1'},
      \ {'lnum': 7, 'id': 2, 'name': 'iced_dummy2', 'group': 'default'},
      \ ])

  let list = s:sign.list_in_buffer(s:foo_file)
  call sort(list, {a, b -> a.lnum > b.lnum})
  call map(list, {_, v -> iced#util#select_keys(v, ['lnum', 'id', 'name', 'group'])})
  call s:assert.equals(list, actual_signs)

  call s:teardown()
endfunction

function! s:suite.jump_to_next_test() abort
  call s:setup()
  exec printf(':b %d', bufnr(s:foo_file))

  call s:assert.equals(getcurpos()[1:2], [1, 1])
  call s:sign.jump_to_next()
  call s:assert.equals(getcurpos()[1:2], [3, 1])
  call s:sign.jump_to_next()
  call s:assert.equals(getcurpos()[1:2], [5, 1])
  call s:sign.jump_to_next()
  call s:assert.equals(getcurpos()[1:2], [7, 1])
  call s:sign.jump_to_next()
  call s:assert.equals(getcurpos()[1:2], [3, 1])

  call s:teardown()
endfunction

function! s:suite.jump_to_prev_test() abort
  call s:setup()
  exec printf(':b %d', bufnr(s:foo_file))

  call s:assert.equals(getcurpos()[1:2], [1, 1])
  call s:sign.jump_to_prev()
  call s:assert.equals(getcurpos()[1:2], [7, 1])
  call s:sign.jump_to_prev()
  call s:assert.equals(getcurpos()[1:2], [5, 1])
  call s:sign.jump_to_prev()
  call s:assert.equals(getcurpos()[1:2], [3, 1])
  call s:sign.jump_to_prev()
  call s:assert.equals(getcurpos()[1:2], [7, 1])

  call s:teardown()
endfunction

function! s:suite.unplace_by_default_group_test() abort
  call s:setup()

  call s:assert.equals(s:list_in_buffer(), [
        \ {'lnum': 3, 'id': 1, 'name': 'iced_dummy1', 'group': 'default'},
        \ {'lnum': 5, 'id': 1, 'name': 'iced_dummy1', 'group': 'group1'},
        \ {'lnum': 7, 'id': 2, 'name': 'iced_dummy2', 'group': 'default'},
        \ ])

  call s:sign.unplace_by({'file': s:foo_file})
  call s:assert.equals(s:list_in_buffer(), [
        \ {'lnum': 5, 'id': 1, 'name': 'iced_dummy1', 'group': 'group1'},
        \ ])

  call s:teardown()
endfunction

function! s:suite.unplace_by_specified_group_test() abort
  call s:setup()

  call s:assert.equals(s:list_in_buffer(), [
        \ {'lnum': 3, 'id': 1, 'name': 'iced_dummy1', 'group': 'default'},
        \ {'lnum': 5, 'id': 1, 'name': 'iced_dummy1', 'group': 'group1'},
        \ {'lnum': 7, 'id': 2, 'name': 'iced_dummy2', 'group': 'default'},
        \ ])

  call s:sign.unplace_by({'file': s:foo_file, 'group': 'group1'})
  call s:assert.equals(s:list_in_buffer(), [
        \ {'lnum': 3, 'id': 1, 'name': 'iced_dummy1', 'group': 'default'},
        \ {'lnum': 7, 'id': 2, 'name': 'iced_dummy2', 'group': 'default'},
        \ ])

  call s:sign.unplace_by({'file': s:foo_file, 'group': '*'})
  call s:assert.equals(s:list_in_buffer(), [])

  call s:teardown()
endfunction

function! s:suite.unplace_by_id_test() abort
  call s:setup()

  call s:assert.equals(s:list_in_buffer(), [
        \ {'lnum': 3, 'id': 1, 'name': 'iced_dummy1', 'group': 'default'},
        \ {'lnum': 5, 'id': 1, 'name': 'iced_dummy1', 'group': 'group1'},
        \ {'lnum': 7, 'id': 2, 'name': 'iced_dummy2', 'group': 'default'},
        \ ])

  call s:sign.unplace_by({'file': s:foo_file, 'group': '*', 'id': 2})
  call s:assert.equals(s:list_in_buffer(), [
        \ {'lnum': 3, 'id': 1, 'name': 'iced_dummy1', 'group': 'default'},
        \ {'lnum': 5, 'id': 1, 'name': 'iced_dummy1', 'group': 'group1'},
        \ ])

  call s:teardown()
endfunction

function! s:suite.unplace_by_name_test() abort
  call s:setup()

  call s:assert.equals(s:list_in_buffer(), [
        \ {'lnum': 3, 'id': 1, 'name': 'iced_dummy1', 'group': 'default'},
        \ {'lnum': 5, 'id': 1, 'name': 'iced_dummy1', 'group': 'group1'},
        \ {'lnum': 7, 'id': 2, 'name': 'iced_dummy2', 'group': 'default'},
        \ ])

  call s:sign.unplace_by({'file': s:foo_file, 'group': '*', 'name': 'iced_dummy1'})
  call s:assert.equals(s:list_in_buffer(), [
        \ {'lnum': 7, 'id': 2, 'name': 'iced_dummy2', 'group': 'default'},
        \ ])

  call s:teardown()
endfunction

function! s:suite.refresh_test() abort
  call s:setup()
  exec printf(':b %d', bufnr(s:foo_file))

  let before_list_in_buffer = s:list_in_buffer()
  let before_ids = map(copy(before_list_in_buffer), {_, v -> v['id']})

  call s:assert.equals(
      \ map(copy(before_list_in_buffer), {_, v -> s:dissoc(v, 'id')}),
      \ [
      \   {'lnum': 3, 'name': 'iced_dummy1', 'group': 'default'},
      \   {'lnum': 5, 'name': 'iced_dummy1', 'group': 'group1'},
      \   {'lnum': 7, 'name': 'iced_dummy2', 'group': 'default'},
      \ ])

  call s:sign.refresh({'file': s:foo_file})

  let after_list_in_buffer = s:list_in_buffer()
  let after_ids = map(copy(after_list_in_buffer), {_, v -> v['id']})

  call s:assert.equals(
      \ map(copy(after_list_in_buffer), {_, v -> s:dissoc(v, 'id')}),
      \ [
      \   {'lnum': 3, 'name': 'iced_dummy1', 'group': 'default'},
      \   {'lnum': 5, 'name': 'iced_dummy1', 'group': 'group1'},
      \   {'lnum': 7, 'name': 'iced_dummy2', 'group': 'default'},
      \ ])

  call s:assert.not_equals(before_ids, after_ids)

  call s:teardown()
endfunction
