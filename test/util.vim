let s:suite  = themis#suite('iced.util')
let s:assert = themis#helper('assert')

function! s:suite.escape_test() abort
  call s:assert.equals('hello', iced#util#escape('hello'))
  call s:assert.equals('he\"llo', iced#util#escape('he"llo'))
  call s:assert.equals('he\\\"llo', iced#util#escape('he\"llo'))
  call s:assert.equals('he\\nllo', iced#util#escape('he\nllo'))
endfunction

function! s:suite.unescape_test() abort
  call s:assert.equals('hello', iced#util#unescape('hello'))
  call s:assert.equals('he"llo', iced#util#unescape('he\"llo'))
  call s:assert.equals('he\"llo', iced#util#unescape('he\\\"llo'))
  call s:assert.equals('he\nllo', iced#util#unescape('he\\nllo'))
endfunction

function! s:suite.ensure_array_test() abort
  call s:assert.equals(['foo'], iced#util#ensure_array('foo'))
  call s:assert.equals(['foo'], iced#util#ensure_array(['foo']))
  call s:assert.equals([['foo']], iced#util#ensure_array([['foo']]))
endfunction

function! s:suite.has_status_test() abort
  call s:assert.equals(v:true, iced#util#has_status({'status': ['foo']}, 'foo'))
  call s:assert.equals(v:true, iced#util#has_status([{'status': ['foo']}], 'foo'))
  call s:assert.equals(v:true, iced#util#has_status(
        \ [{'status': ['foo']}, {'status': ['bar']}], 'foo'))
  call s:assert.equals(v:true, iced#util#has_status(
        \ [{'status': ['foo']}, {'status': ['bar']}], 'bar'))

  call s:assert.equals(v:false, iced#util#has_status({'status': ['foo']}, 'bar'))
  call s:assert.equals(v:false, iced#util#has_status([{'status': ['foo']}], 'bar'))
  call s:assert.equals(v:false, iced#util#has_status(
        \ [{'status': ['foo']}, {'status': ['bar']}], 'baz'))
endfunction

function! s:suite.add_indent_test() abort
  call s:assert.equals(
        \ iced#util#add_indent(2, "foo\nbar\n  baz"),
        \ "foo\n  bar\n    baz")

  call s:assert.equals(iced#util#add_indent(10, 'foo'), 'foo')
endfunction

function! s:suite.del_indent_test() abort
  call s:assert.equals(
        \ iced#util#del_indent(2,  "foo\n  bar\n    baz"),
        \ "foo\nbar\n  baz")
  call s:assert.equals(iced#util#del_indent(10, 'foo'), 'foo')
endfunction

function! s:suite.partition_test() abort
  call s:assert.equals(iced#util#partition([1, 2, 3, 4], 2, v:false),
        \ [[1, 2], [3, 4]])
  call s:assert.equals(iced#util#partition([1, 2, 3, 4, 5], 2, v:false),
        \ [[1, 2], [3, 4]])
  call s:assert.equals(iced#util#partition([1, 2, 3, 4, 5], 2, v:true),
        \ [[1, 2], [3, 4], [5]])
  call s:assert.equals(iced#util#partition([], 2, v:false),
        \ [])
  call s:assert.equals(iced#util#partition([1, 2], 1, v:false),
        \ [[1], [2]])
  call s:assert.equals(iced#util#partition([1, 2], 1, v:true),
        \ [[1], [2]])
endfunction

function! s:suite.save_read_var_test() abort
  let name = tempname()
  try
    let v = {'foo': 123, 'bar': [4, 5, 6]}
    call iced#util#save_var(v, name)
    call s:assert.true(filewritable(name))

    let a = iced#util#read_var(name)
    call s:assert.equals(v, a)
  finally
    call delete(name)
  endtry
endfunction

function! s:suite.shorten_test() abort
  let current_columns = &columns
  let current_cmdheight = max([&cmdheight, 1])
  let current_showcmd = &showcmd
  let current_laststatus = &laststatus


  try
    set columns=20
    set cmdheight=1
    set noshowcmd
    set laststatus=2

    let text = '0123456789'
    call s:assert.equals(iced#util#shorten(text), '0123456789')

    " This test depends on the value of `v:echospace`, so it's OK if the long string is shortened"
    let text = ''
    for _ in range(10)
      let text = printf('%s0123456789', text)
    endfor

    let result = iced#util#shorten(text)
    call s:assert.true(len(result) < len(text))
    call s:assert.true(match(result, '\.\.\.$') != -1)
  finally
    exec printf('set columns=%d', current_columns)
    exec printf('set cmdheight=%d', current_cmdheight)
    exec printf('set laststatus=%d', current_laststatus)
    if current_showcmd | set showcmd | endif
  endtry
endfunction

function! s:suite.char_repeat_test() abort
  call s:assert.equals(iced#util#char_repeat(3, '.'), '...')
  call s:assert.equals(iced#util#char_repeat(0, '.'), '')
  call s:assert.equals(iced#util#char_repeat(-3, '.'), '')
endfunction

function! s:suite.select_keys_test() abort
  let d = {'a': 1, 'b': 2, 'c': 3}

  call s:assert.equals(iced#util#select_keys(d, ['a', 'b']), {'a': 1, 'b': 2})
  call s:assert.equals(iced#util#select_keys(d, ['c', 'd']), {'c': 3})
  call s:assert.equals(iced#util#select_keys(d, ['d']), {})
endfunction

function! s:suite.normalize_path_test() abort
  call s:assert.equals(iced#util#normalize_path('/foo/bar.txt'),
        \ '/foo/bar.txt')
  call s:assert.equals(iced#util#normalize_path('jar:file:/path/to/jarfile.jar!/path/to/file.clj'),
        \ 'zipfile:/path/to/jarfile.jar::path/to/file.clj')
endfunction

function! s:suite.list_to_dict_test() abort
  let sample = [{'k': 'one', 'v': 1}, {'k': 'two', 'v': 2}]

  call s:assert.equals(iced#util#list_to_dict(sample, {v -> v.k}, {v -> v}),
        \ {'one': {'k': 'one', 'v': 1}, 'two': {'k': 'two', 'v': 2}})
  call s:assert.equals(iced#util#list_to_dict(sample, {v -> v.k}, {v -> v.v}),
        \ {'one': 1, 'two': 2})
endfunction
