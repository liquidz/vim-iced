let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:concat_handler(key, resp, last_result) abort
  let result = empty(a:last_result) ? [] : a:last_result
  for resp in iced#util#ensure_array(a:resp)
    if has_key(resp, a:key)
      call extend(result, resp[a:key])
    endif
  endfor
  return result
endfunction

""" lint-file {{{
function! iced#nrepl#op#iced#is_lint_running() abort
  return iced#nrepl#is_op_running('iced-lint-file')
endfunction

function! iced#nrepl#op#iced#lint_file(file, opt, callback) abort
  if !iced#nrepl#is_connected() | return | endif

  let msg = {
      \ 'id': iced#nrepl#id(),
      \ 'op': 'iced-lint-file',
      \ 'session': iced#nrepl#current_session(),
      \ 'env': iced#nrepl#current_session_key(),
      \ 'file': a:file,
      \ 'callback': a:callback,
      \ }

  if !empty(a:opt) && type(a:opt) == v:t_dict
    let msg['opt'] = a:opt
  endif

  call iced#nrepl#send(msg)
endfunction " }}}

""" grimoire {{{
function! iced#nrepl#op#iced#grimoire(platform, ns_name, symbol, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  call iced#nrepl#send({
        \ 'op': 'iced-grimoire',
        \ 'session': iced#nrepl#current_session(),
        \ 'platform': a:platform,
        \ 'ns': a:ns_name,
        \ 'symbol': a:symbol,
        \ 'callback': a:callback,
        \ })
endfunction " }}}

""" spec-check {{{
function! iced#nrepl#op#iced#spec_check(symbol, num_tests, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'iced-spec-check',
        \ 'session': iced#nrepl#current_session(),
        \ 'symbol': a:symbol,
        \ 'num-tests': a:num_tests,
        \ 'callback': a:callback,
        \ })
endfunction " }}}

""" project-ns-list {{{
function! iced#nrepl#op#iced#project_ns_list(callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'iced-project-ns-list',
        \ 'session': iced#nrepl#current_session(),
        \ 'callback': a:callback,
        \ })
endfunction " }}}

""" pseudo-ns-path {{{
function! iced#nrepl#op#iced#pseudo_ns_path(ns, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'iced-pseudo-ns-path',
        \ 'ns': a:ns,
        \ 'session': iced#nrepl#current_session(),
        \ 'callback': a:callback,
        \ })
endfunction " }}}

""" list-tapped {{{
function! iced#nrepl#op#iced#list_tapped(callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'iced-list-tapped',
        \ 'session': iced#nrepl#current_session(),
        \ 'callback': a:callback,
        \ })
endfunction " }}}

""" clear-tapped {{{
function! iced#nrepl#op#iced#clear_tapped(callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'iced-clear-tapped',
        \ 'session': iced#nrepl#current_session(),
        \ 'callback': a:callback,
        \ })
endfunction " }}}

""" browse-tapped {{{
function! iced#nrepl#op#iced#browse_tapped(keys, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'iced-browse-tapped',
        \ 'keys': a:keys,
        \ 'session': iced#nrepl#current_session(),
        \ 'callback': a:callback,
        \ })
endfunction " }}}

""" complete-tapped {{{
function! iced#nrepl#op#iced#complete_tapped(keys, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'iced-complete-tapped',
        \ 'keys': a:keys,
        \ 'session': iced#nrepl#current_session(),
        \ 'callback': a:callback,
        \ })
endfunction " }}}

call iced#nrepl#register_handler('iced-lint-file', function('s:concat_handler', ['lint-warnings']))

let &cpoptions = s:save_cpo
unlet s:save_cpo
" vim:fdm=marker:fdl=0
