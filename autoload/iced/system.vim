let s:save_cpo = &cpoptions
set cpoptions&vim

let s:component_cache = {}

      "\ 'nrepl':        {'start': 'iced#component#nrepl#start', 'requires': ['bencode', 'channel']},
      "\ 'session':      {'start': 'iced#component#session#start', 'requires': ['nrepl']},
let s:system_map = {
      \ 'vim_bencode':  {'start': 'iced#component#bencode#vim#start'},
      \ 'bencode':      {'start': 'iced#component#bencode#start',
      \                  'requires': ['vim_bencode']},
      \ 'channel':      {'start': 'iced#component#channel#start'},
      \ 'ex_cmd':       {'start': 'iced#component#ex_cmd#start'},
      \ 'io':           {'start': 'iced#component#io#start'},
      \ 'job':          {'start': 'iced#component#job#start'},
      \ 'quickfix':     {'start': 'iced#component#quickfix#start'},
      \ 'selector':     {'start': 'iced#component#selector#start'},
      \ 'sign':         {'start': 'iced#component#sign#start',
      \                  'requires': ['ex_cmd']},
      \ 'tagstack':     {'start': 'iced#component#tagstack#start'},
      \ 'timer':        {'start': 'iced#component#timer#start'},
      \ 'popup':        {'start': 'iced#component#popup#start'},
      \ 'virtual_text': {'start': 'iced#component#virtual_text#start',
      \                  'vim_requires': ['popup', 'ex_cmd'],
      \                  'nvim_requires': ['timer']},
      \ }

function! s:requires(name) abort
  let specific_key = has('nvim') ? 'nvim_requires' : 'vim_requires'
  let requires = copy(get(s:system_map[a:name], 'requires', []))
  call extend(requires, copy(get(s:system_map[a:name], specific_key, [])))
  return requires
endfunction

function! iced#system#set_component(name, component_map) abort
  if has_key(s:component_cache, a:name)
    unlet s:component_cache[a:name]
  endif

  for component_name in keys(s:system_map)
    if !has_key(s:component_cache, component_name) | continue | endif

    let requires = s:requires(component_name)
    if index(requires, a:name) != -1
      unlet s:component_cache[component_name]
    endif
  endfor

  let s:system_map[a:name] = copy(a:component_map)
endfunction

function! iced#system#get(name) abort
  if has_key(s:component_cache, a:name)
    return s:component_cache[a:name]
  else
    if !has_key(s:system_map, a:name) | return '' | endif

    let params = {}
    for required_component_name in s:requires(a:name)
      let params[required_component_name] = iced#system#get(required_component_name)
    endfor
    let StartFn = s:system_map[a:name]['start']
    if type(StartFn) == v:t_string
      let StartFn = function(StartFn)
    endif
    let s:component_cache[a:name] = StartFn(params)
    return s:component_cache[a:name]
  endif
endfunction

function! s:stop(name) abort
  if !has_key(s:system_map, a:name) || !has_key(s:component_cache, a:name)
    return ''
  endif

  for required_component_name in s:requires(a:name)
    call s:stop(required_component_name)
  endfor

  if has_key(s:system_map[a:name], 'stop')
    let StopFn = s:system_map[a:name]['stop']
    if type(StopFn) == v:t_string
      let StopFn = function(StopFn)
    endif
    call StopFn(s:component_cache[a:name])
  endif

  unlet s:component_cache[a:name]
endfunction

function! iced#system#stop() abort
  for name in keys(s:system_map)
    call s:stop(name)
  endfor
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
