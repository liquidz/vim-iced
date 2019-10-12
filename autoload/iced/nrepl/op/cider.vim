let s:save_cpo = &cpo
set cpo&vim

""" complete {{{
function! iced#nrepl#op#cider#complete(base, ns_name, context, callback) abort
  if !iced#nrepl#is_connected()
    return iced#message#error('not_connected')
  endif

  let msg = {
        \ 'op': 'complete',
        \ 'session': iced#nrepl#current_session(),
        \ 'ns': a:ns_name,
        \ 'symbol': a:base,
        \ 'extra-metadata': ['arglists', 'doc'],
        \ 'callback': a:callback,
        \ }

  if !empty(a:context)
    let msg['context'] = a:context
  endif

  if g:iced_enable_enhanced_cljs_completion
    let msg['enhanced-cljs-completion?'] = 't'
  endif

  return iced#nrepl#send(msg)
endfunction " }}}

""" info {{{
function! iced#nrepl#op#cider#info(ns_name, symbol, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
      \ 'op': 'info',
      \ 'session': iced#nrepl#current_session(),
      \ 'symbol': a:symbol,
      \ 'ns': a:ns_name,
      \ 'callback': a:callback,
      \ })
endfunction " }}}

""" ns-path {{{
function! iced#nrepl#op#cider#ns_path(ns, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
      \ 'op': 'ns-path',
      \ 'session': iced#nrepl#current_session(),
      \ 'ns': a:ns,
      \ 'callback': a:callback,
      \ })
endfunction " }}}

""" ns-list {{{
function! iced#nrepl#op#cider#ns_list(callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
      \ 'op': 'ns-list',
      \ 'session': iced#nrepl#current_session(),
      \ 'callback': a:callback,
      \ })
endfunction " }}}

""" ns-load-all {{{
function! iced#nrepl#op#cider#ns_load_all(callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
      \ 'op': 'ns-load-all',
      \ 'session': iced#nrepl#current_session(),
      \ 'callback': a:callback,
      \ })
endfunction " }}}

""" test-var-query {{{

" var_query examples)
" * testing var
"   {'ns-query': {'exactly': ['foo.core']}, 'exactly': ['foo.core/bar-test']}
" * testing ns
"   {'ns-query': {'exactly': ['foo.core']}}
" * testing all
"   {'ns-query': {'project?': 'true', 'load-project-ns?': 'true'}}
function! iced#nrepl#op#cider#test_var_query(var_query, callback) abort
  if iced#nrepl#is_connected()
    call iced#nrepl#send({
        \ 'op': 'test-var-query',
        \ 'session': iced#nrepl#current_session(),
        \ 'id': iced#nrepl#id(),
        \ 'var-query': a:var_query,
        \ 'callback': a:callback,
        \ })
  endif
endfunction " }}}

""" retest {{{
function! iced#nrepl#op#cider#retest(callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
      \ 'op': 'retest',
      \ 'session': iced#nrepl#current_session(),
      \ 'id': iced#nrepl#id(),
      \ 'callback': a:callback,
      \ })
endfunction " }}}

""" undef {{{
function! iced#nrepl#op#cider#undef(symbol, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
      \ 'op': 'undef',
      \ 'session': iced#nrepl#current_session(),
      \ 'ns': iced#nrepl#ns#name(),
      \ 'symbol': a:symbol,
      \ 'verbose': v:false,
      \ 'callback': a:callback,
      \ })
endfunction " }}}

""" macroexpand {{{
function! iced#nrepl#op#cider#macroexpand_1(code, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
      \ 'id': iced#nrepl#id(),
      \ 'op': 'macroexpand',
      \ 'ns': iced#nrepl#ns#name(),
      \ 'code': a:code,
      \ 'session': iced#nrepl#current_session(),
      \ 'expander': 'macroexpand-1',
      \ 'callback': a:callback,
      \ })
endfunction

function! iced#nrepl#op#cider#macroexpand_all(code, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
      \ 'id': iced#nrepl#id(),
      \ 'op': 'macroexpand',
      \ 'ns': iced#nrepl#ns#name(),
      \ 'code': a:code,
      \ 'session': iced#nrepl#current_session(),
      \ 'expander': 'macroexpand-all',
      \ 'callback': a:callback,
      \ })
endfunction " }}}

""" toggle-trace-ns {{{
function! iced#nrepl#op#cider#toggle_trace_ns(ns_name, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
      \ 'op': 'toggle-trace-ns',
      \ 'ns': a:ns_name,
      \ 'session': iced#nrepl#current_session(),
      \ 'callback': a:callback,
      \ })
endfunction " }}}

""" toggle-trace-var {{{
function! iced#nrepl#op#cider#toggle_trace_var(ns_name, symbol, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
      \ 'op': 'toggle-trace-var',
      \ 'ns': a:ns_name,
      \ 'sym': a:symbol,
      \ 'session': iced#nrepl#current_session(),
      \ 'callback': a:callback,
      \ })
endfunction " }}}

""" spec-list {{{
function! iced#nrepl#op#cider#spec_list(callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
      \ 'op': 'spec-list',
      \ 'session': iced#nrepl#current_session(),
      \ 'callback': a:callback,
      \ })
endfunction " }}}

""" spec-form {{{
function! iced#nrepl#op#cider#spec_form(spec_name, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
      \ 'op': 'spec-form',
      \ 'spec-name': a:spec_name,
      \ 'session': iced#nrepl#current_session(),
      \ 'callback': a:callback,
      \ })
endfunction " }}}

""" spec-example {{{
function! iced#nrepl#op#cider#spec_example(spec_name, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
      \ 'op': 'spec-example',
      \ 'spec-name': a:spec_name,
      \ 'session': iced#nrepl#current_session(),
      \ 'callback': a:callback,
      \ })
endfunction " }}}

""" fn-refs {{{
function! iced#nrepl#op#cider#fn_refs(ns_name, symbol, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
        \ 'op': 'fn-refs',
        \ 'id': iced#nrepl#id(),
        \ 'ns': a:ns_name,
        \ 'sym': a:symbol,
        \ 'session': iced#nrepl#current_session(),
        \ 'callback': a:callback,
        \ })
endfunction " }}}

""" fn-deps {{{
function! iced#nrepl#op#cider#fn_deps(ns_name, symbol, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
        \ 'op': 'fn-deps',
        \ 'id': iced#nrepl#id(),
        \ 'ns': a:ns_name,
        \ 'sym': a:symbol,
        \ 'session': iced#nrepl#current_session(),
        \ 'callback': a:callback,
        \ })
endfunction " }}}

""" clojuredocs-lookup {{{
function! iced#nrepl#op#cider#clojuredocs_lookup(ns, name, export_edn_url, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'clojuredocs-lookup',
        \ 'ns': a:ns,
        \ 'sym': a:name,
        \ 'export-edn-url': a:export_edn_url,
        \ 'session': iced#nrepl#current_session(),
        \ 'callback': a:callback,
        \ })
endfunction " }}}

""" clojuredocs-refresh-cache {{{
function! iced#nrepl#op#cider#clojuredocs_refresh_cache(export_edn_url, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'clojuredocs-refresh-cache',
        \ 'export-edn-url': a:export_edn_url,
        \ 'session': iced#nrepl#current_session(),
        \ 'callback': a:callback,
        \ })
endfunction " }}}

call iced#nrepl#register_handler('info', function('iced#nrepl#merge_response_handler'))
call iced#nrepl#register_handler('test-var-query', function('iced#nrepl#extend_responses_handler'))
call iced#nrepl#register_handler('retest', function('iced#nrepl#extend_responses_handler'))

let &cpo = s:save_cpo
unlet s:save_cpo
" vim:fdm=marker:fdl=0
