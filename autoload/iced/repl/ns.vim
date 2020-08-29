let s:save_cpo = &cpoptions
set cpoptions&vim

let s:V = vital#iced#new()
let s:L = s:V.import('Data.List')

function! s:__list(callback, resp) abort
  let list = get(a:resp, 'value', '')
  let list = split(substitute(list, '(\|)', '', 'g'), ' \+')

	let kondo = iced#system#get('clj_kondo')
	if kondo.is_analyzed()
		let list += kondo.used_ns_list()
		let list = s:L.uniq(list)
	endif

  " as same as cider-nrepl's ns-list op
  return a:callback({'ns-list': copy(list)})
endfunction

function! iced#repl#ns#list(callback) abort
  call iced#repl#execute('eval_code', '(map ns-name (all-ns))', {
        \ 'callback': funcref('s:__list', [a:callback]),
        \ })
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
