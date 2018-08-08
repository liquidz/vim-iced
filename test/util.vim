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
