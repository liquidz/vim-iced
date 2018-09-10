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
