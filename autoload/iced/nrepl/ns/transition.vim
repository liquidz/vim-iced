let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:S = s:V.import('Data.String')

function! s:open(mode, ns_name) abort
  let resp = iced#nrepl#op#cider#sync#ns_path(a:ns_name)
  if !has_key(resp, 'path') || empty(resp['path']) || !filereadable(resp['path'])
    return iced#message#error('not_found')
  endif

  let cmd = ':edit'
  if a:mode ==# 'v'
    let cmd = ':split'
  elseif a:mode ==# 't'
    let cmd = ':tabedit'
  endif
  exe printf('%s %s', cmd, resp['path'])
endfunction

function! iced#nrepl#ns#transition#cycle(ns) abort
  return (s:S.ends_with(a:ns, '-test')
      \ ? substitute(a:ns, '-test$', '', '')
      \ : a:ns . '-test'
      \ )
endfunction

function! iced#nrepl#ns#transition#toggle_src_and_test() abort
  if !iced#nrepl#is_connected()
    return iced#message#error('not_connected')
  endif

  let ns = iced#nrepl#ns#name()
  let toggle_ns = iced#nrepl#ns#transition#cycle(ns)
  call s:open('e', toggle_ns)
endfunction

"let s:cache_name = 'namespaces'

function! s:select_ns_from_list(namespaces) abort
  if empty(a:namespaces) | return iced#message#error('not_found') | endif
  "call ctrlp#iced#cache#write(s:cache_name, a:namespaces)
  call ctrlp#iced#start({'candidates': a:namespaces, 'accept': funcref('s:open')})
endfunction

function! iced#nrepl#ns#transition#list() abort
  " if ctrlp#iced#cache#exists(s:cache_name)
  "   let lines = ctrlp#iced#cache#read(s:cache_name)
  "   call ctrlp#iced#start({'candidates': lines, 'accept': funcref('s:open')})
  " else
    call iced#message#info('fetching')
    call iced#nrepl#op#iced#project_namespaces(funcref('s:select_ns_from_list'))
  " endif
endfunction

function! iced#nrepl#ns#transition#related() abort
  let ns_name = iced#nrepl#ns#name()
  call iced#message#info('fetching')
  call iced#nrepl#op#iced#related_namespaces(ns_name, funcref('s:select_ns_from_list'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
