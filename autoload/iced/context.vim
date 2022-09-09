let s:save_cpo = &cpoptions
set cpoptions&vim

let s:last_context = ''

function! iced#context#input() abort
  call inputsave()
  let context = iced#system#get('io').input(iced#message#get('evaluation_context'), s:last_context)
  call inputrestore()

  if empty(context) | return '' | endif
  let s:last_context = context
	return s:last_context
endfunction

function! iced#context#wrap_code(context, code) abort
	return printf('(clojure.core/let [%s] %s)', a:context, a:code)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
