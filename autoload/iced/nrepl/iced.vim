let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#iced#lint_file(file, linters, callback) abort
  if !iced#nrepl#is_connected() | return | endif

  let msg = {
      \ 'id': iced#nrepl#eval#id(),
      \ 'op': 'lint-file',
      \ 'sesion': iced#nrepl#current_session(),
      \ 'file': a:file,
      \ 'callback': a:callback,
      \ }

  if !empty(a:linters) && type(a:linters) == type([])
    let msg['linters'] = a:linters
  endif

  call iced#nrepl#send(msg)
endfunction

function! iced#nrepl#iced#grimoire(platform, ns_name, symbol, callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  call iced#nrepl#send({
        \ 'op': 'grimoire',
        \ 'sesion': iced#nrepl#current_session(),
        \ 'platform': a:platform,
        \ 'ns': a:ns_name,
        \ 'symbol': a:symbol,
        \ 'callback': a:callback,
        \ })
endfunction

function! iced#nrepl#iced#project_namespaces(callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  call iced#nrepl#send({
        \ 'op': 'project-namespaces',
        \ 'sesion': iced#nrepl#current_session(),
        \ 'callback': a:callback,
        \ })
endfunction

let s:candidates = []
function! s:concat_candidates_handler(resp) abort
  if has_key(a:resp, 'candidates')
    call extend(s:candidates, a:resp['candidates'])
  endif
  return s:candidates
endfunction

function! iced#nrepl#iced#everywhere(callback) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let s:candidates = []
  call iced#nrepl#send({
        \ 'id': iced#nrepl#eval#id(),
        \ 'op': 'everywhere',
        \ 'sesion': iced#nrepl#current_session(),
        \ 'file': expand('%:p'),
        \ 'callback': a:callback,
        \ })
endfunction

call iced#nrepl#register_handler('lint-file')
call iced#nrepl#register_handler('grimoire')
call iced#nrepl#register_handler('project-namespaces')
call iced#nrepl#register_handler('everywhere', funcref('s:concat_candidates_handler'))

let &cpo = s:save_cpo
unlet s:save_cpo
