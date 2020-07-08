let s:save_cpo = &cpoptions
set cpoptions&vim

let s:default_source_root = executable('ghq')
     \ ? trim(system('git config ghq.root'))
     \ : ''
let g:iced#source_root = get(g:, 'iced#source_root', s:default_source_root)

let s:enabled_lookup = v:true

function! iced#nrepl#sideloader#toggle_enablement_of_lookup() abort
  let s:enabled_lookup = !s:enabled_lookup

  if s:enabled_lookup
    return iced#message#info('enable_sideloader_lookup')
  endif
  return iced#message#info('disable_sideloader_lookup')
endfunction

function! iced#nrepl#sideloader#start() abort
  if !iced#nrepl#is_connected() | return | endif
  if !executable('base64')
    return iced#message#error('not_installed', 'base64')
  endif

  if empty(g:iced#source_root)
    return iced#message#error('no_source_root')
  endif

  call iced#nrepl#send({
      \ 'op': 'sideloader-start',
      \ 'session': iced#nrepl#current_session(),
      \ 'callback': {_ -> ''},
      \ 'does_not_capture_id': v:true,
      \ })
  call iced#message#info('started_sideloader')
endfunction

function! iced#nrepl#sideloader#stop() abort
  " NOTE: nrepl doesn't have a op to stop sideloader.
  "       but sideloader is a session specific mode,
  "       so we can stop sideloading by stopping to use current session.
  if !iced#nrepl#is_connected() | return | endif

  let current_session = iced#nrepl#clj_session()
  return iced#nrepl#clone(current_session,
        \ {resp -> iced#nrepl#set_session('clj', resp['new-session']) ||
        \          iced#nrepl#close(current_session,
        \                           {_ -> iced#message#info('stopped_sideloader')})})
endfunction

function! s:lookup(file, callback) abort
  if empty(a:file)
    return a:callback('')
  endif

  call iced#system#get('job_out').redir(printf('base64 %s', a:file), a:callback)
endfunction

function! s:provide(session, type, name, content) abort
  if !empty(a:content)
    call iced#message#info('provided_sideloader', a:name, a:type)
  endif

  call iced#nrepl#send({
        \ 'op': 'sideloader-provide',
        \ 'session': a:session,
        \ 'type': a:type,
        \ 'name': a:name,
        \ 'content': a:content,
        \ 'does_not_capture_id': v:true,
        \ })
endfunction

function! iced#nrepl#sideloader#lookup(resp) abort
  if !has_key(a:resp, 'name') || !has_key(a:resp, 'type') | return | endif

  let name = a:resp['name']
  let session = a:resp['session']
  let type = a:resp['type']

  if !s:enabled_lookup
    " Empty content means that there are no corresponding codes.
    return s:provide(session, type, name, '')
  endif

  call iced#system#get('find').file(g:iced#source_root, name, {file ->
        \ s:lookup(file, {content ->
        \   s:provide(session, type, name, content)})})
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
