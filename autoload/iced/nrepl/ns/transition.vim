let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('iced')
let s:S = s:V.import('Data.String')

function! s:toggle(resp) abort
  if has_key(a:resp, 'path') && !empty(a:resp['path'])
    execute printf(':edit %s', a:resp['path'])
  else
    echom iced#message#get('not_found')
  endif
endfunction

function! iced#nrepl#ns#toggle#src_and_test() abort
  let ns = iced#nrepl#ns#name()
  if s:S.ends_with(ns, '-test')
    let toggle_ns = substitute(ns, '-test$', '', '')
  else
    let toggle_ns = ns . '-test'
  endif

  call iced#nrepl#cider#ns_path(toggle_ns, funcref('s:toggle'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
