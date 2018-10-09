let s:save_cpo = &cpo
set cpo&vim

let s:concat_results = {}
function! s:concat_handler(key, resp) abort
  for resp in iced#util#ensure_array(a:resp)
    if has_key(resp, a:key)
      call extend(s:concat_results[a:key], resp[a:key])
    endif
  endfor
  return s:concat_results[a:key]
endfunction

""" lint-file {{{
function! iced#nrepl#op#iced#lint_file(file, linters, callback) abort
  if !iced#nrepl#is_connected() | return | endif

  let msg = {
      \ 'id': iced#nrepl#eval#id(),
      \ 'op': 'lint-file',
      \ 'sesion': iced#nrepl#current_session(),
      \ 'env': iced#nrepl#current_session_key(),
      \ 'file': a:file,
      \ 'callback': a:callback,
      \ }

  if !empty(a:linters) && type(a:linters) == type([])
    let msg['linters'] = a:linters
  endif

  let s:concat_results['lint-warnings'] = []
  call iced#nrepl#send(msg)
endfunction " }}}

""" grimoire {{{
function! iced#nrepl#op#iced#grimoire(platform, ns_name, symbol, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  call iced#nrepl#send({
        \ 'op': 'grimoire',
        \ 'sesion': iced#nrepl#current_session(),
        \ 'platform': a:platform,
        \ 'ns': a:ns_name,
        \ 'symbol': a:symbol,
        \ 'callback': a:callback,
        \ })
endfunction " }}}

""" project-namespaces {{{
function! iced#nrepl#op#iced#project_namespaces(callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  let s:concat_results['namespaces'] = []
  call iced#nrepl#send({
        \ 'id': iced#nrepl#eval#id(),
        \ 'op': 'project-namespaces',
        \ 'sesion': iced#nrepl#current_session(),
        \ 'callback': a:callback,
        \ })
endfunction " }}}

""" project-functions {{{
function! iced#nrepl#op#iced#project_functions(callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  let s:concat_results['functions'] = []
  call iced#nrepl#send({
        \ 'id': iced#nrepl#eval#id(),
        \ 'op': 'project-functions',
        \ 'sesion': iced#nrepl#current_session(),
        \ 'callback': a:callback,
        \ })
endfunction " }}}

call iced#nrepl#register_handler('lint-file', {resp -> s:concat_handler('lint-warnings', resp)})
call iced#nrepl#register_handler('project-namespaces', {resp -> s:concat_handler('namespaces', resp)})
call iced#nrepl#register_handler('project-functions', {resp -> s:concat_handler('functions', resp)})

let &cpo = s:save_cpo
unlet s:save_cpo
