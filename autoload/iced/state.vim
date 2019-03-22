let s:save_cpo = &cpo
set cpo&vim

let s:V  = vital#iced#new()
let s:L  = s:V.import('Data.List')

let s:states_order = []
let s:states = {}
let s:last_starting_params = {}

function! iced#state#define(name, definition) abort " {{{
  if type(a:definition) != v:t_dict | return | endif
  if !s:L.has(s:states_order, a:name)
    call add(s:states_order, a:name)
  endif
  let s:states[a:name] = {'definition': a:definition, 'state': ''}
endfunction " }}}

function! iced#state#define_by_dict(dict) abort " {{{
  for state_name in keys(a:dict)
    let definition = a:dict[state_name]
    call iced#state#define(state_name, definition)
  endfor
endfunction " }}}

function! iced#state#start_by_name(name) abort " {{{
  if !has_key(s:states, a:name) | return | endif

  let state_def = s:states[a:name]['definition']
  if has_key(state_def, 'start') && type(state_def.start) == v:t_func
    let params = copy(s:last_starting_params)
    if has_key(state_def, 'require') && type(state_def.require) == v:t_list
      let params['require'] = {}
      for required_state_name in state_def.require
        let params['require'][required_state_name] = iced#state#get(required_state_name, v:true)
      endfor
    endif

    let new_state = state_def.start(params)
    if !empty(new_state)
      let s:states[a:name]['state'] = new_state
      return v:true
    endif
  endif

  return v:false
endfunction " }}}

function! iced#state#start(...) abort " {{{
  let starting_params = get(a:, 1, {})
  let s:last_starting_params = starting_params
  let result = v:true

  for state_name in s:states_order
    if has_key(s:states, state_name)
          \ && get(s:states[state_name]['definition'], 'lazy', v:false)
      continue
    endif

    let result = result && iced#state#start_by_name(state_name)
  endfor

  return result
endfunction " }}}

function! iced#state#stop() abort " {{{
  for state_name in reverse(copy(s:states_order))
    let state_def = s:states[state_name]['definition']
    if has_key(state_def, 'stop') && type(state_def.stop) == v:t_func
      let current_state = s:states[state_name]['state']
      call state_def.stop(current_state)
    endif

    let s:states[state_name]['state'] = ''
  endfor
endfunction " }}}

function! iced#state#get(name, ...) abort " {{{
  if !has_key(s:states, a:name) | return | endif

  let does_force_start = get(a:, 1, v:false)

  if empty(s:states[a:name]['state'])
        \ && (does_force_start || get(s:states[a:name]['definition'], 'lazy', v:false))
    call iced#state#start_by_name(a:name)
  endif

  return s:states[a:name]['state']
endfunction " }}}

call iced#state#define_by_dict({
     \ 'cache': {'start': function('iced#state#cache#start'),
     \           'lazy': v:true},
     \ 'ex_cmd': {'start': function('iced#state#ex_cmd#start')},
     \ 'quickfix': {'start': function('iced#state#quickfix#start')},
     \ 'selector': {'start': function('iced#state#selector#start')},
     \ 'virtual_text': {'start': function('iced#state#virtual_text#start')},
     \
     \ 'buffer': {'start': function('iced#state#buffer#start'),
     \            'require': ['ex_cmd']},
     \ 'stdout_buffer': {'start': function('iced#state#buffer#stdout#start'),
     \                   'require': ['buffer']},
     \ 'error_buffer': {'start': function('iced#state#buffer#error#start'),
     \                  'require': ['buffer']},
     \ 'document_buffer': {'start': function('iced#state#buffer#document#start'),
     \                     'require': ['buffer']},
     \ 'floating_buffer': {'start': function('iced#state#buffer#floating#start'),
     \                     'require': ['buffer']},
     \
     \ 'bencode': {'start': function('iced#state#bencode#start')},
     \ 'channel': {'start': function('iced#state#channel#start')},
     \ 'nrepl': {'start': function('iced#state#nrepl#start'),
     \           'stop': function('iced#state#nrepl#stop'),
     \           'require': ['bencode', 'channel']},
     \ })

let &cpo = s:save_cpo
unlet s:save_cpo
" vim:fdm=marker:fdl=0
