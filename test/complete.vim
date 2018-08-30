let s:suite  = themis#suite('iced.complete')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:funcs = s:scope.funcs('autoload/iced/complete.vim')

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

function! s:suite.ns_alias_candidates_test() abort
  let dummy_aliases = ['foo', 'bar', 'baz']
  call s:assert.equals(
      \ s:funcs.ns_alias_candidates(dummy_aliases, 'ba'),
      \ [{'candidate': 'bar', 'type': 'namespace'}, {'candidate': 'baz', 'type': 'namespace'}])

  call s:assert.true(empty(s:funcs.ns_alias_candidates(dummy_aliases, 'nomatch')))
endfunction
