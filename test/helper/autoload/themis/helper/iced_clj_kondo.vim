let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {}

function! s:install(_, callback) abort
  return a:callback('ok')
endfunction

function! s:helper.mock(analysis) abort
  let org = iced#component#clj_kondo#start({
        \ 'job_out': '',
        \ 'clj_kondo_option': {},
        \ 'installer': {'install': funcref('s:install')},
        \ })
  let mock = deepcopy(org)
  let mock.is_analyzed = {-> v:true}
  let mock.is_analyzing = {-> v:false}
  let mock.cache_name = {-> '.dummy_cache_name'}
  let mock.namespace_usages_cache_name = {-> '.dummy_ns_usages_cache_name'}
  let mock.analysis = {-> a:analysis}

  call iced#system#set_component('clj_kondo', {'start': {_ -> mock}})
endfunction

function! themis#helper#iced_clj_kondo#new(runner) abort
  return deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
