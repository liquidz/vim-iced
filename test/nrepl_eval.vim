let s:suite  = themis#suite('iced.nrepl.eval')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:funcs = s:scope.funcs('autoload/iced/nrepl/eval.vim')

let s:test_1_9_error =
      \ 'CompilerException java.lang.RuntimeException: Unable to resolve symbol: a in this context, compiling:(/path/to/src.clj:12:34)'

let s:test_1_10_error =
      \ "Syntax error compiling at (/path/to/src.clj:12:34).\nUnable to resolve symbol: a in this context"

function! s:suite.parse_error_1_9_or_above_test() abort
  call s:assert.equals(s:funcs.parse_error(s:test_1_9_error),
        \ {'filename': '/path/to/src.clj',
        \  'lnum': '12',
        \  'text': 'CompilerException java.lang.RuntimeException: Unable to resolve symbol: a in this context'})
endfunction

function! s:suite.parse_error_1_10_or_later_test() abort
  call s:assert.equals(s:funcs.parse_error(s:test_1_10_error),
        \ {'filename': '/path/to/src.clj',
        \  'lnum': '12',
        \  'text': 'Unable to resolve symbol: a in this context'})
endfunction

function! s:suite.parse_error_invalid_message_test() abort
  call s:assert.true(empty(s:funcs.parse_error('invalid message')))
endfunction
