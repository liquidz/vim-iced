let s:save_cpo = &cpo
set cpo&vim

function! s:common_replace(s) abort
  let s = substitute(a:s, 'clojure.spec.alpha', 's', '')
  return substitute(s, 'clojure.core/', '', 'g')
endfunction

function! iced#nrepl#spec#format(spec) abort
  if type(a:spec) != type([])
    return empty(a:spec) ? 'nil' : s:common_replace(a:spec)
  endif

  let fn = s:common_replace(a:spec[0])
  let args = join(map(a:spec[1:], {_, v -> iced#nrepl#spec#format(v)}), ' ')
  return printf('(%s %s)', fn, args)
endfunction

function! s:spec_form(resp) abort
  if !has_key(a:resp, 'spec-form')
    return iced#message#error('spec_form_error')
  endif

  let formatted = trim(iced#nrepl#spec#format(a:resp['spec-form']))
  if empty(formatted)
    return iced#message#warn('no_spec')
  endif
  call iced#buffer#document#open(formatted, 'clojure')
endfunction

function! s:browse_spec(spec_name) abort
  call iced#nrepl#cider#spec_form(a:spec_name, funcref('s:spec_form'))
endfunction

function! s:spec_list(resp) abort
  if !has_key(a:resp, 'spec-list') || empty(a:resp['spec-list'])
    return iced#message#error('spec_list_error')
  endif

  let list = a:resp['spec-list']
  if len(list) == 1
    call s:browse_spec(list[0])
  else
    call ctrlp#iced#start({
        \ 'candidates': list,
        \ 'accept': {_, spec_name -> s:browse_spec(spec_name)},
        \ })
  endif
endfunction

function! iced#nrepl#spec#list() abort
  call iced#nrepl#cider#spec_list(funcref('s:spec_list'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
