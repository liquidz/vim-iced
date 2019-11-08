let s:save_cpo = &cpoptions
set cpoptions&vim

" Must be the same I/F with 'future#timer' component
let s:instant = {}
function! s:instant.do(fn) abort
	return a:fn()
endfunction

function! iced#component#future#instant#start(this) abort
  return s:instant
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
