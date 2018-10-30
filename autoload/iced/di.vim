let s:save_cpo = &cpo
set cpo&vim

let s:container = {}

function! s:default_builder(name) abort
  let l:res = ''
  exe printf('let l:res = iced#di#%s#build()', a:name)
  return l:res
endfunction

function! s:value(name) abort
  return a:name.'.value'
endfunction

function! iced#di#register(name, builder) abort
  let s:container[a:name] = a:builder
  if has_key(s:container, s:value(a:name))
    unlet s:container[s:value(a:name)]
  endif
endfunction

function! iced#di#build(name) abort
  let Builder = get(s:container, a:name, function('s:default_builder', [a:name]))
  let value_name = s:value(a:name)
  let s:container[value_name] = Builder()
  return s:container[value_name]
endfunction

function! iced#di#get(name) abort
  return get(s:container, s:value(a:name), iced#di#build(a:name))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
