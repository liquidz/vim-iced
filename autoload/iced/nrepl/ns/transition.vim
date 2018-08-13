let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('iced')
let s:S = s:V.import('Data.String')

function! s:open_response(mode, resp) abort
  if !has_key(a:resp, 'path') || empty(a:resp['path'])
    return iced#message#error('not_found')
  endif

  let cmd = ':edit'
  if a:mode ==# 'v'
    let cmd = ':split'
  elseif a:mode ==# 't'
    let cmd = ':tabedit'
  endif
  exe printf('%s %s', cmd, a:resp['path'])
endfunction

function! s:open(mode, ns_name) abort
  call iced#nrepl#cider#ns_path(a:ns_name,
      \ {resp -> s:open_response(a:mode, resp)})
endfunction

function! iced#nrepl#ns#transition#toggle_src_and_test() abort
  if !iced#nrepl#is_connected()
    return iced#message#error('not_connected')
  endif

  let ns = iced#nrepl#ns#name()
  if s:S.ends_with(ns, '-test')
    let toggle_ns = substitute(ns, '-test$', '', '')
  else
    let toggle_ns = ns . '-test'
  endif

  call s:open('e', toggle_ns)
endfunction

function! s:select_ns_from_list(list) abort
  if empty(a:list)
    return iced#message#error('not_found')
  endif

  call ctrlp#iced#start({
      \ 'candidates': a:list,
      \ 'accept': funcref('s:open'),
      \ })
endfunction

function! iced#nrepl#ns#transition#list() abort
  call iced#nrepl#cider#project_namespaces(funcref('s:select_ns_from_list'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
