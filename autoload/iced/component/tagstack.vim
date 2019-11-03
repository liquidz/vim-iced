let s:save_cpo = &cpoptions
set cpoptions&vim

let s:tagstack = {}

function! s:tagstack.add(winid, bufnr, lnum, cnum, tagname) abort
  let stack = gettagstack(a:winid)
  let items = stack['items']
  let new_item = {
        \ 'bufnr': a:bufnr,
        \ 'from': [a:bufnr, a:lnum, a:cnum, 0],
        \ 'tagname': a:tagname,
        \ }

  let tailidx = stack['curidx'] - 2
  let items = (tailidx < 0) ? [] : stack['items'][0:tailidx]
  let items = items + [new_item]

  let stack['curidx'] += 1
  let stack['items'] = items
  return settagstack(a:winid, stack, 'r')
endfunction

function! s:tagstack.add_here() abort
  return self.add(win_getid(), bufnr('%'), line('.'), col('.'), iced#nrepl#var#cword())
endfunction

function! iced#component#tagstack#start(_) abort
  return s:tagstack
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
