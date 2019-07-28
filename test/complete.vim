let s:suite  = themis#suite('iced.complete')
let s:assert = themis#helper('assert')
let s:scope  = themis#helper('scope')
let s:ch     = themis#helper('iced_channel')
let s:buf    = themis#helper('iced_buffer')
let s:funcs  = s:scope.funcs('autoload/iced/complete.vim')

function! s:suite.candidate_test() abort
  let dummy = {
      \ 'arglists': ['foo', '(quote bar)'],
      \ 'doc': 'baz',
      \ 'candidate': 'hello',
      \ 'type': 'function',
      \ }
  call s:assert.equals(
      \ s:funcs.candidate(dummy),
      \ {'word': 'hello', 'kind': 'f', 'menu': 'foo bar', 'info': 'baz', 'icase': 1})
endfunction

function! s:suite.candidate_without_arglists_test() abort
  let dummy = {
      \ 'doc': 'baz',
      \ 'candidate': 'hello',
      \ 'type': 'function',
      \ }
  call s:assert.equals(
      \ s:funcs.candidate(dummy),
      \ {'word': 'hello', 'kind': 'f', 'menu': '', 'info': 'baz', 'icase': 1})
endfunction

function! s:suite.candidate_without_doc_test() abort
  let dummy = {
      \ 'arglists': ['foo', '(quote bar)'],
      \ 'candidate': 'hello',
      \ 'type': 'function',
      \ }
  call s:assert.equals(
      \ s:funcs.candidate(dummy),
      \ {'word': 'hello', 'kind': 'f', 'menu': 'foo bar', 'info': '', 'icase': 1})
endfunction

function! s:suite.context_test() abort
  call s:buf.start_dummy([
        \ '(defn foo [x]',
        \ '  (let [y 1]',
        \ '    (+ | y)))',
        \ ])
  call s:assert.equals(s:funcs.context(), join([
        \ '(defn foo [x]',
        \ '  (let [y 1]',
        \ '    (+ __prefix__ y)))',
        \ ], "\n"))
  call s:buf.stop_dummy()
endfunction

function! s:suite.context_failure_test() abort
  call s:buf.start_dummy(['invalid| text'])
  call s:assert.equals(s:funcs.context(), '')
  call s:buf.stop_dummy()
endfunction

function! s:suite.omni_findstart_test() abort
  call s:buf.start_dummy([
        \ '(defn foo [x]',
        \ '  (let [y 1]',
        \ '    (+ | y)))',
        \ ])
  call s:assert.equals(iced#complete#omni(v:true, 'base'), 7)
  call s:buf.stop_dummy()
endfunction
