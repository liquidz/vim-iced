let s:suite  = themis#suite('iced.nrepl.complete')
let s:assert = themis#helper('assert')
let s:scope  = themis#helper('scope')
let s:ch     = themis#helper('iced_channel')
let s:buf    = themis#helper('iced_buffer')
let s:funcs  = s:scope.funcs('autoload/iced/nrepl/complete.vim')

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

" function! s:__candidates_cider_relay(msg) abort
"   let op = a:msg['op']
"   if op ==# 'describe'
"     return {'status': ['done'], 'ops': {'complete': 1}}
"   elseif op ==# 'complete'
"     return {'status': ['done'], 'completions': [
"          \ {'candidate': 'foo'},
"          \ {'candidate': 'bar'},
"          \ {'candidate': 'cider'}]}
"   else
"     return {'status': ['done']}
"   endif
" endfunction

" function! s:suite.candidates_cider_complete_test() abort
"   call s:buf.start_dummy(['(ns foo.core)|'])
"   call s:ch.mock({'status_value': 'open', 'relay': funcref('s:__candidates_cider_relay')})
"   let g:iced_enable_enhanced_cljs_completion = v:false
"   let g:iced#nrepl#complete#ignore_context = v:true
"
"   let res = iced#promise#sync('iced#nrepl#complete#candidates', ['dummy base'])
"   call s:assert.equals(res, [
"        \ {'word': 'bar', 'menu': '', 'info': '', 'kind': 'v', 'icase': 1},
"        \ {'word': 'cider', 'menu': '', 'info': '', 'kind': 'v', 'icase': 1},
"        \ {'word': 'foo', 'menu': '', 'info': '', 'kind': 'v', 'icase': 1},
"        \ ])
"
"   call s:buf.stop_dummy()
" endfunction
"
" function! s:__candidates_nrepl_relay(msg) abort
"   let op = a:msg['op']
"   if op ==# 'describe'
"     return {'status': ['done'], 'ops': {'completions': 1}}
"   elseif op ==# 'completions'
"     return {'status': ['done'], 'completions': [
"          \ {'candidate': 'foo'},
"          \ {'candidate': 'bar'},
"          \ {'candidate': 'nrepl'}]}
"   else
"     return {'status': ['done']}
"   endif
" endfunction
"
" function! s:suite.candidates_nrepl_completions_test() abort
"   call s:buf.start_dummy(['(ns foo.core)|'])
"   call s:ch.mock({'status_value': 'open', 'relay': funcref('s:__candidates_nrepl_relay')})
"   let g:iced_enable_enhanced_cljs_completion = v:false
"   let g:iced#nrepl#complete#ignore_context = v:true
"
"   let res = iced#promise#sync('iced#nrepl#complete#candidates', ['dummy base'])
"   call s:assert.equals(res, [
"        \ {'word': 'bar', 'menu': '', 'info': '', 'kind': 'v', 'icase': 1},
"        \ {'word': 'foo', 'menu': '', 'info': '', 'kind': 'v', 'icase': 1},
"        \ {'word': 'nrepl', 'menu': '', 'info': '', 'kind': 'v', 'icase': 1},
"        \ ])
"
"   call s:buf.stop_dummy()
" endfunction
