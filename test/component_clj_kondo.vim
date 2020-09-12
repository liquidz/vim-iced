let s:suite  = themis#suite('iced.component.clj_kondo')
let s:assert = themis#helper('assert')
let s:job_out = themis#helper('iced_job_out')

let s:kondo = ''

function! s:setup() abort
  let g:iced_cache_directory = '/tmp'
  let g:iced_enable_clj_kondo_analysis = v:true

  call s:job_out.mock({'outs': ['']})
  call iced#system#reset_component('clj_kondo')
  let s:kondo = iced#system#get('clj_kondo')
endfunction

function! s:teardown() abort
  let g:iced_enable_clj_kondo_analysis = v:false
  let s:kondo = ''
endfunction

function! s:suite.cache_name_test() abort
  call s:setup()
  let name = s:kondo.cache_name()
  call s:assert.true(match(name, '^/tmp/.\+\.json$') == 0)
  call s:teardown()
endfunction

function! s:suite.namespace_usages_cache_name_test() abort
  call s:setup()
  let name = s:kondo.namespace_usages_cache_name()
  call s:assert.true(match(name, '^/tmp/.\+_ns_usages\.json$') == 0)
  call s:teardown()
endfunction

function! s:suite.analyze_test() abort
  call s:setup()
  let res = iced#promise#sync(s:kondo.analyze, [])
  call s:assert.equals(res, s:kondo.cache_name())
  call s:teardown()
endfunction

function! s:suite.is_analyzed_test() abort
  call s:setup()
  call s:assert.false(s:kondo.is_analyzed())

  let name = s:kondo.cache_name()
  call writefile([''], name)
  call s:assert.true(s:kondo.is_analyzed())
  call delete(name)
  call s:teardown()
endfunction

function! s:suite.analysis_test() abort
  call s:setup()
  let name = s:kondo.cache_name()
  call writefile(['{"analysis": {"foo": "bar"}}'], name)

  let res = s:kondo.analysis()
  call s:assert.equals(res, {'foo': 'bar'})

  call delete(name)
  call s:teardown()
endfunction

function! s:suite.namespace_usages_test() abort
  call s:setup()
  let name = s:kondo.cache_name()
  call writefile(['{"analysis": {"foo": "bar", "namespace-usages": {"bar": "baz"}}}'], name)

  let res = s:kondo.namespace_usages()
  call s:assert.equals(res, {'bar': 'baz'})

  call delete(name)
  call s:teardown()
endfunction
