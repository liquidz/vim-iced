let s:suite  = themis#suite('iced.component.clj_kondo')
let s:assert = themis#helper('assert')
let s:job_out = themis#helper('iced_job_out')

let s:kondo = ''

function! s:setup() abort
  let g:iced_cache_directory = '/tmp'
  let g:iced_enable_clj_kondo_analysis = v:true
  let g:iced_enable_clj_kondo_local_analysis = v:true

  call s:job_out.mock({'outs': ['']})
  call iced#system#reset_component('clj_kondo')
  let s:kondo = iced#system#get('clj_kondo')
endfunction

function! s:teardown() abort
  let g:iced_enable_clj_kondo_analysis = v:false
  let g:iced_enable_clj_kondo_local_analysis = v:false
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

function! s:suite.namespace_definitions_cache_name_test() abort
  call s:setup()
  let name = s:kondo.namespace_definitions_cache_name()
  call s:assert.true(match(name, '^/tmp/.\+_ns_definitions\.json$') == 0)
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
  call writefile(['{"analysis": {"foo": "bar", "namespace-usages": {"ns_usages": "foo"}}}'], name)

  let res = s:kondo.namespace_usages()
  call s:assert.equals(res, {'ns_usages': 'foo'})

  call delete(name)
  call s:teardown()
endfunction

function! s:suite.namespace_usages_cache_test() abort
  call s:setup()
  let name = s:kondo.namespace_usages_cache_name()
  call writefile(['{"ns_usages": "bar"}'], name)

  let res = s:kondo.namespace_usages()
  call s:assert.equals(res, {'ns_usages': 'bar'})

  call delete(name)
  call s:teardown()
endfunction

function! s:suite.namespace_definitions_test() abort
  call s:setup()
  let name = s:kondo.cache_name()
  call writefile(['{"analysis": {"foo": "bar", "namespace-definitions": {"ns_defs": "foo"}}}'], name)

  let res = s:kondo.namespace_definitions()
  call s:assert.equals(res, {'ns_defs': 'foo'})

  call delete(name)
  call s:teardown()
endfunction

function! s:suite.namespace_definitions_cache_test() abort
  call s:setup()
  let name = s:kondo.namespace_definitions_cache_name()
  call writefile(['{"ns_defs": "bar"}'], name)

  let res = s:kondo.namespace_definitions()
  call s:assert.equals(res, {'ns_defs': 'bar'})

  call delete(name)
  call s:teardown()
endfunction

function! s:suite.used_ns_list_test() abort
  call s:setup()
  let name = s:kondo.namespace_usages_cache_name()
  call writefile(['[{"to": "ns1"}, {"to": "ns2"}, {"to": "ns1"}]'], name)

  let res = s:kondo.used_ns_list()
  call s:assert.equals(res, ['ns1', 'ns2'])

  call delete(name)
  call s:teardown()
endfunction

function! s:suite.var_definition_test() abort
  call s:setup()
  let name = s:kondo.cache_name()
  let json = json_encode({
        \'analysis': {'var-definitions': [
        \   {'ns': 'ns1', 'name': 'var1', 'foo': 'bar'},
        \   {'ns': 'ns2', 'name': 'var2', 'bar': 'baz'},
        \   ]},
        \ })
  call writefile([json], name)

  let res = s:kondo.var_definition('ns1', 'var1')
  call s:assert.equals(res, {'ns': 'ns1', 'name': 'var1', 'foo': 'bar'})

  call s:assert.true(empty(s:kondo.var_definition('ns1', 'unknown var')))
  call s:assert.true(empty(s:kondo.var_definition('unknown ns', 'var1')))

  call delete(name)
  call s:teardown()
endfunction

function! s:suite.ns_path_test() abort
  call s:setup()
  let name = s:kondo.namespace_definitions_cache_name()
  let json = json_encode([
        \ {'name': 'ns1', 'filename': '/path/to/ns1.clj'},
        \ {'name': 'ns2', 'filename': '/path/to/ns2.clj'},
        \ ])
  call writefile([json], name)

  let res = s:kondo.ns_path('ns1')
  call s:assert.equals(res, '/path/to/ns1.clj')

  call s:assert.true(empty(s:kondo.ns_path('unknown ns')))

  call delete(name)
  call s:teardown()
endfunction
