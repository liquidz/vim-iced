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
let s:does_all_ns_loaded = v:false

function! s:ns_list(resp) abort
  if !has_key(a:resp, 'ns-list') | return iced#message#error('ns_list_error') | endif

  let s:does_all_ns_loaded = v:true

  let ns = iced#nrepl#ns#name()
  let arr = split(ns, '\.')
  let ns_head = arr[0]
  let ns_tail = substitute(arr[len(arr)-1], '-test$', '', '')
  let pattern = printf('^%s\.\(.\+\.\)\?\(%s\)$',
        \ ns_head,
        \ join(map(copy(g:iced#related_ns#tail_patterns),
        \          {_, v -> printf('%s%s', ns_tail, v)}), '\|'))

  let related = filter(copy(a:resp['ns-list']), {_, v -> (v !=# ns && match(v, pattern) != -1)})
  if empty(related) | return iced#message#error('not_found') | endif
  call iced#selector({'candidates': related, 'accept': funcref('s:open')})
endfunction

function! iced#nrepl#navigate#related_ns() abort
  if !s:does_all_ns_loaded
    call iced#message#echom('all_ns_loading')
    call iced#nrepl#op#cider#ns_load_all({_ -> iced#nrepl#op#cider#ns_list(funcref('s:ns_list'))})
  else
    call iced#nrepl#op#cider#ns_list(funcref('s:ns_list'))
  endif
endfunction " }}}

" iced#nrepl#navigate#jump_to_def {{{
function! s:jump(resp) abort
  if !has_key(a:resp, 'file') | return iced#message#error('jump_not_found') | endif
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

  let ns_name = iced#nrepl#ns#name()
  let kw = empty(a:symbol) ? expand('<cword>') : a:symbol
  call iced#nrepl#op#cider#info(ns_name, kw, function('s:jump'))
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
