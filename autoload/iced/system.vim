let s:save_cpo = &cpoptions
set cpoptions&vim

let s:component_cache = {}
let s:nvim = has('nvim')

let s:system_map = {
      \ 'vim_bencode':  {'start': 'iced#component#bencode#vim#start'},
      \ 'bencode':      {'start': 'iced#component#bencode#start',
      \                  'requires': ['vim_bencode']},
      \ 'channel':      {'start': (s:nvim ? 'iced#component#channel#neovim#start'
      \                                   : 'iced#component#channel#vim#start')},
      \ 'ex_cmd':       {'start': 'iced#component#ex_cmd#start'},
      \ 'io':           {'start': 'iced#component#io#start'},
      \ 'job':          {'start': (s:nvim ? 'iced#component#job#neovim#start'
      \                                   : 'iced#component#job#vim#start')},
      \ 'quickfix':     {'start': 'iced#component#quickfix#start'},
      \ 'selector':     {'start': 'iced#component#selector#start'},
      \ 'sign':         {'start': 'iced#component#sign#start',
      \                  'requires': ['ex_cmd']},
      \ 'tagstack':     {'start': 'iced#component#tagstack#start'},
      \ 'timer':        {'start': 'iced#component#timer#start'},
      \ 'future':       {'start': 'iced#component#future#timer#start',
      \                  'requires': ['timer']},
      \ 'popup_config': {'start': 'iced#component#popup#config#start'},
      \ 'popup':        {'start': (s:nvim ? 'iced#component#popup#neovim#start'
      \                                   : 'iced#component#popup#vim#start'),
      \                  'requires': ['popup_config']},
      \ 'virtual_text': (s:nvim ? {'start': 'iced#component#virtual_text#neovim#start',
      \                            'requires': ['timer']}
      \                         : {'start': 'iced#component#virtual_text#vim#start',
      \                            'requires': ['popup', 'ex_cmd']}),
      \ 'installer':    {'start': 'iced#component#installer#start',
      \                  'requires': ['io', 'job']},
      \ 'edn':          {'start': 'iced#component#edn#start',
      \                  'requires': ['installer', 'job']},
      \ 'nrepl':        {'start': 'iced#component#repl#nrepl#start'},
      \ 'socket_repl':  {'start': 'iced#component#repl#socket_repl#start'},
      \ 'prepl':        {'start': 'iced#component#repl#prepl#start',
      \                  'requires': ['socket_repl', 'edn']},
      \ 'format_default':      {'start': 'iced#component#format#nrepl#start',
      \                         'requires': ['sign']},
      \ 'format_native_image': {'start': 'iced#component#format#native_image#start',
      \                         'requires': ['sign', 'job']},
      \ 'format_cljstyle':     {'start': 'iced#component#format#cljstyle#start',
      \                         'requires': ['installer', 'format_native_image']},
      \ 'format_zprint':       {'start': 'iced#component#format#zprint#start',
      \                         'requires': ['installer', 'format_native_image']},
      \ }

function! s:requires(name) abort
  let requires = get(s:system_map[a:name], 'requires', [])
  return copy(requires)
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
      let req = iced#system#get(required_component_name)
      if empty(req)
        call iced#message#error('component_error', required_component_name)
        return ''
      endif
      let params[required_component_name] = iced#system#get(required_component_name)
    endfor

    let StartFn = s:system_map[a:name]['start']
    if type(StartFn) == v:t_string
      let StartFn = function(StartFn)
    endif

    let component = StartFn(params)
    if type(component) == v:t_dict
      let s:component_cache[a:name] = component
    else
      call iced#message#error('component_error', a:name)
    endif
    return component
  endif
endfunction

function! s:stop(name) abort
  if !has_key(s:system_map, a:name) || !has_key(s:component_cache, a:name)
    return ''
  endif

  for required_component_name in s:requires(a:name)
    call s:stop(required_component_name)
  endfor

  let m = s:system_map[a:name]
  if has_key(m, 'stop')
    let StopFn = m['stop']
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
