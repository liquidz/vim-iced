let s:save_cpo = &cpoptions
set cpoptions&vim

let s:prefixes = [
      \ '',
      \ 'file:',
      \ 'jar:file:',
      \ ]

function! iced#nrepl#path#replace(s, from, to) abort
  let i = stridx(a:s, a:from)
  if i == -1 | return a:s | endif

  let prefix = (i == 0) ? '' : a:s[0:i-1]
  if index(s:prefixes, prefix) == -1
    return a:s
  endif

  let j = i + len(a:from)
  return printf('%s%s%s', prefix, a:to, strpart(a:s, j))
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
