let s:save_cpo = &cpoptions
set cpoptions&vim

function! iced#complete#candidates(base, callback) abort
  let res = iced#repl#execute('complete_candidates', a:base, a:callback)
  if !res
    return a:callback([])
  endif
endfunction

function! iced#complete#omni(findstart, base) abort
  if a:findstart
    let line = getline('.')
    let ncol = col('.')
    let s = line[0:ncol-2]
    return ncol - strlen(matchstr(s, '\k\+$')) - 1
  else
    return iced#promise#sync('iced#complete#candidates', [a:base], 10000)
  endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
