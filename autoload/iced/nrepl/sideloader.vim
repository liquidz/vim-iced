let s:save_cpo = &cpoptions
set cpoptions&vim

let s:default_source_root = executable('ghq')
     \ ? trim(system('ghq root'))
     \ : ''
let g:iced#source_root = get(g:, 'iced#source_root', s:default_source_root)

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
      \ 'callback': {_ -> iced#message#info('started_sideloader')},
      \ })
endfunction

function! s:lookup(file, callback) abort
  if empty(a:file)
    return a:callback('')
  endif

  call iced#system#get('job').out(printf('base64 %s', a:file), a:callback)
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

  call iced#system#get('find').file(g:iced#source_root, name, {file ->
        \ s:lookup(file, {content ->
        \   s:provide(session, type, name, content)})})
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
