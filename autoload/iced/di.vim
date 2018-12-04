let s:save_cpo = &cpo
set cpo&vim

function! iced#di#new_container() abort
  let container = {}

  function! container.register(name, builder) abort
    if type(a:builder) != 2 | return | endif
    let self[a:name] = a:builder
  endfunction

  function! container.get(name) abort
    let Builder = get(self, a:name, '')
    if type(Builder) != 2 | return | endif
    return Builder(self)
  endfunction

  return container
endfunction

let s:container_cache = {}

function! iced#di#register(name, builder) abort
  if has_key(s:container_cache, a:name)
    unlet s:container_cache[a:name]
  endif
  return g:iced#di#container.register(a:name, a:builder)
endfunction

function! iced#di#get(name) abort
  if !has_key(s:container_cache, a:name)
    let s:container_cache[a:name] = g:iced#di#container.get(a:name)
  endif
  return s:container_cache[a:name]
endfunction

" Initializer {{{
if !exists('g:iced#di#container')
  let g:iced#di#container = iced#di#new_container()
  call iced#di#register('channel',  {_ -> iced#di#channel#build()})
  call iced#di#register('bencode',  {_ -> iced#di#bencode#build()})
  call iced#di#register('sign',     {_ -> iced#di#sign#build()})
  call iced#di#register('ex_cmd',   {_ -> iced#di#ex_cmd#build()})
  call iced#di#register('selector', {_ -> iced#di#selector#build()})
  call iced#di#register('vim',      {_ -> iced#di#vim#build()})
endif " }}}

let &cpo = s:save_cpo
unlet s:save_cpo
