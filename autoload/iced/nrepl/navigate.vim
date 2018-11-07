let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:S = s:V.import('Data.String')
let s:L = s:V.import('Data.List')

let s:tagstack = []
let g:iced#related_ns#tail_patterns =
      \ get(g:, 'iced#related_ns#tail_patterns', ['', '-test', '-spec', '\.spec'])

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

" iced#nrepl#navigate#cycle_ns {{{
function! iced#nrepl#navigate#cycle_ns(ns) abort
  return (s:S.ends_with(a:ns, '-test')
      \ ? substitute(a:ns, '-test$', '', '')
      \ : a:ns . '-test')
endfunction " }}}

" iced#nrepl#navigate#toggle_src_and_test {{{
function! iced#nrepl#navigate#toggle_src_and_test() abort
  if !iced#nrepl#is_connected()
    return iced#message#error('not_connected')
  endif

  let ns = iced#nrepl#ns#name()
  let toggle_ns = iced#nrepl#navigate#cycle_ns(ns)
  call s:open('e', toggle_ns)
endfunction " }}}

" iced#nrepl#navigate#related_ns {{{
function! s:select_ns_from_list(namespaces) abort
  if empty(a:namespaces) | return iced#message#error('not_found') | endif
  call iced#selector({'candidates': a:namespaces, 'accept': funcref('s:open')})
endfunction

function! iced#nrepl#navigate#related_ns() abort
  let ns_name = iced#nrepl#ns#name()
  call iced#message#info('fetching')
  call iced#nrepl#op#iced#related_namespaces(ns_name, funcref('s:select_ns_from_list'))
endfunction " }}}

" iced#nrepl#navigate#jump_to_def {{{
function! s:jump(resp) abort
  let path = substitute(a:resp['file'], '^file:', '', '')
  let line = a:resp['line']
  let column = a:resp['column']

  if stridx(path, 'jar:') == 0
    return iced#message#error('jump_error', path)
  endif

  if expand('%:p') !=# path
    execute(printf(':edit %s', path))
  endif

  call cursor(line, column)
  normal! zz
  redraw!
endfunction

function! iced#nrepl#navigate#jump_to_def(symbol) abort
  let pos = getcurpos()
  let pos[0] = bufnr('%')
  call s:L.push(s:tagstack, pos)

  let kw = empty(a:symbol) ? expand('<cword>') : a:symbol
  call iced#nrepl#op#cider#info(kw, function('s:jump'))
endfunction " }}}

" iced#nrepl#navigate#jump_back {{{
function! iced#nrepl#navigate#jump_back() abort
  if empty(s:tagstack)
    echo 'Local tag stack is empty'
  else
    let last_position = s:L.pop(s:tagstack)
    execute printf(':buffer %d', last_position[0])
    call cursor(last_position[1], last_position[2])
    normal! zz
    redraw!
  endif
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo
" vim:fdm=marker:fdl=0
