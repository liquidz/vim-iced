let s:save_cpo = &cpoptions
set cpoptions&vim

let s:component_cache = {}

let s:system_map = {
      \ 'vim_bencode':  {'constructor': 'iced#component#bencode#vim#new'},
      \ 'bencode':      {'constructor': 'iced#component#bencode#new', 'requires': ['vim_bencode']},
      \ 'channel':      {'constructor': 'iced#component#channel#new', 'requires': ['bencode']},
      \ 'nrepl':        {'constructor': 'iced#component#nrepl#new', 'requires': ['channel']},
      \ 'session':      {'constructor': 'iced#component#session#new', 'requires': ['nrepl']},
      \ 'ex_cmd':       {'constructor': 'iced#component#ex_cmd#new'},
      \ 'io':           {'constructor': 'iced#component#io#new'},
      \ 'job':          {'constructor': 'iced#component#job#new'},
      \ 'quickfix':     {'constructor': 'iced#component#quickfix#new'},
      \ 'selector':     {'constructor': 'iced#component#selector#new'},
      \ 'timer':        {'constructor': 'iced#component#timer#new'},
      \ 'virtual_text': {'constructor': 'iced#component#virtual_text#new',
      \                  'vim_requires': ['popup', 'ex_cmd'],
      \                  'nvim_requires': ['timer']},
      \ }

function! s:requires(name) abort
  let specific_key = has('nvim') ? 'nvim_requires' : 'vim_requires'
  let requires = copy(get(s:system_map[a:name], 'requires', []))
  call extend(requires, get(s:system_map[a:name], specific_key, []))
  return requires
endfunction

function! iced#system#set_component_map(name, component_map) abort
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
    let Ctor = s:system_map[a:name]['constructor']
    if type(Ctor) == v:t_string
      let Ctor = function(Ctor)
    endif
    let s:component_cache[a:name] = Ctor(params)
    return s:component_cache[a:name]
  endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
