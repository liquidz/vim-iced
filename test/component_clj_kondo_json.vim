let s:suite  = themis#suite('iced.component.clj_kondo.json')
let s:assert = themis#helper('assert')
let s:job_out = themis#helper('iced_job_out')

let s:kondo_json = ''

function! s:setup() abort
  let g:iced_cache_directory = '/tmp'
  let g:iced_enable_clj_kondo_analysis = v:true
  let g:iced_enable_clj_kondo_local_analysis = v:true

  call s:job_out.mock({'outs': ['']})
  call iced#system#set_component('__clj_kondo_json', {
        \ 'start':  'iced#component#clj_kondo#json#start',
        \ 'requires': ['job_out']})
  let s:kondo_json = iced#system#get('__clj_kondo_json')
endfunction

function! s:teardown() abort
  let g:iced_enable_clj_kondo_analysis = v:false
  let g:iced_enable_clj_kondo_local_analysis = v:false
  let s:kondo_json = ''
endfunction

function! s:suite.namespace_usages_cache_name_test() abort
  call s:setup()
  let name = s:kondo_json.namespace_usages_cache_name()
  call s:assert.true(match(name, '^/tmp/.\+_ns_usages\.json$') == 0)
  call s:teardown()
endfunction

function! s:suite.namespace_definitions_cache_name_test() abort
  call s:setup()
  let name = s:kondo_json.namespace_definitions_cache_name()
  call s:assert.true(match(name, '^/tmp/.\+_ns_definitions\.json$') == 0)
  call s:teardown()
endfunction

function! s:suite.local_definitions_cache_name_test() abort
  call s:setup()
  let name = s:kondo_json.local_definitions_cache_name()
  call s:assert.true(match(name, '^/tmp/.\+_local_definitions\.json$') == 0)
  call s:teardown()
endfunction

function! s:suite.local_usages_cache_name_test() abort
  call s:setup()
  let name = s:kondo_json.local_usages_cache_name()
  call s:assert.true(match(name, '^/tmp/.\+_local_usages\.json$') == 0)
  call s:teardown()
endfunction

function! s:suite.namespace_usages_cache_test() abort
  call s:setup()
  let name = s:kondo_json.namespace_usages_cache_name()
  call writefile(['[{"ns_usages": "bar"}]'], name)

  let res = s:kondo_json.namespace_usages()
  call s:assert.equals(res, [{'ns_usages': 'bar'}])

  call delete(name)
  let res = s:kondo_json.namespace_usages()
  call s:assert.equals(res, [])

  call s:teardown()
endfunction

function! s:suite.namespace_definitions_cache_test() abort
  call s:setup()
  let name = s:kondo_json.namespace_definitions_cache_name()
  call writefile(['[{"ns_defs": "bar"}]'], name)

  let res = s:kondo_json.namespace_definitions()
  call s:assert.equals(res, [{'ns_defs': 'bar'}])

  call delete(name)
  let res = s:kondo_json.namespace_definitions()
  call s:assert.equals(res, [])

  call s:teardown()
endfunction

function! s:suite.local_usages_cache_test() abort
  call s:setup()
  let name = s:kondo_json.local_usages_cache_name()
  call writefile(['[{"local_usages": "bar"}]'], name)

  let res = s:kondo_json.local_usages()
  call s:assert.equals(res, [{'local_usages': 'bar'}])

  call delete(name)
  let res = s:kondo_json.local_usages()
  call s:assert.equals(res, [])

  call s:teardown()
endfunction

function! s:suite.local_definitions_cache_test() abort
  call s:setup()
  let name = s:kondo_json.local_definitions_cache_name()
  call writefile(['[{"local_defs": "bar"}]'], name)

  let res = s:kondo_json.local_definitions()
  call s:assert.equals(res, [{'local_defs': 'bar'}])

  call delete(name)
  let res = s:kondo_json.local_definitions()
  call s:assert.equals(res, [])

  call s:teardown()
endfunction
