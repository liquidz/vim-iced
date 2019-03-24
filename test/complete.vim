let s:suite  = themis#suite('iced.complete')
let s:assert = themis#helper('assert')
let s:scope  = themis#helper('scope')
let s:nrepl  = themis#helper('iced_nrepl')
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

function! s:ns_var_reply(msg) abort
  if a:msg['op'] ==# 'ns-vars-with-meta'
    return {
          \ 'status': ['done'],
          \ 'ns-vars-with-meta': {
          \   'bar': {'arglists': '([] [x])', 'doc': '"aaa\nbbb"'},
          \   'baz': {'arglists': '(quote [x])', 'doc': '"ccc"'},
          \   },
          \ }
  endif
  return {}
endfunction

function! s:suite.ns_var_candidates_without_alias_test() abort
  call s:nrepl.start_test_state({'relay': funcref('s:ns_var_reply')})

  let res = s:funcs.ns_var_candidates('foo.core', 'bar', '')
  call s:assert.equals(len(res), 1)
  call s:assert.equals(res[0]['candidate'], 'bar')
  call s:assert.equals(res[0]['doc'], join([
        \ 'foo.core/bar',
        \ '([] [x])',
        \ '  aaa',
        \ 'bbb',
        \ ], "\n"))
  call s:assert.equals(res[0]['arglists'], ['([] [x])'])
  call s:assert.equals(res[0]['type'], 'var')

  let res = s:funcs.ns_var_candidates('foo.core', 'baz', '')
  call s:assert.equals(len(res), 1)
  call s:assert.equals(res[0]['candidate'], 'baz')
  call s:assert.equals(res[0]['doc'], join([
        \ 'foo.core/baz',
        \ '[x]',
        \ '  ccc',
        \ ], "\n"))
  call s:assert.equals(res[0]['arglists'], ['(quote [x])'])
  call s:assert.equals(res[0]['type'], 'var')

  let res = s:funcs.ns_var_candidates('foo.core', 'b', '')
  let candidates = map(copy(res), {_, v -> v['candidate']})
  if candidates[0] ==# 'bar'
    call s:assert.equals(candidates, ['bar', 'baz'])
  else
    call s:assert.equals(candidates, ['baz', 'bar'])
  endif
endfunction

function! s:suite.ns_var_candidates_with_alias_test() abort
  call s:nrepl.start_test_state({'relay': funcref('s:ns_var_reply')})

  let res = s:funcs.ns_var_candidates('foo.core', 'bar', 'foo')
  call s:assert.equals(len(res), 1)
  call s:assert.equals(res[0]['candidate'], 'foo/bar')
  call s:assert.equals(res[0]['doc'], join([
        \ 'foo.core/bar',
        \ '([] [x])',
        \ '  aaa',
        \ 'bbb',
        \ ], "\n"))
  call s:assert.equals(res[0]['arglists'], ['([] [x])'])
  call s:assert.equals(res[0]['type'], 'var')
endfunction

function! s:suite.ns_alias_candidates_test() abort
  let dummy_aliases = ['foo', 'bar', 'baz']
  call s:assert.equals(
      \ s:funcs.ns_alias_candidates(dummy_aliases, 'ba'),
      \ [{'candidate': 'bar', 'type': 'namespace'}, {'candidate': 'baz', 'type': 'namespace'}])

  call s:assert.true(empty(s:funcs.ns_alias_candidates(dummy_aliases, 'nomatch')))
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
endfunction

function! s:suite.context_failure_test() abort
  call s:buf.start_dummy(['invalid| text'])
  call s:assert.equals(s:funcs.context(), '')
endfunction

function! s:suite.omni_findstart_test() abort
  call s:buf.start_dummy([
        \ '(defn foo [x]',
        \ '  (let [y 1]',
        \ '    (+ | y)))',
        \ ])
  call s:assert.equals(iced#complete#omni(v:true, 'base'), 7)
endfunction
