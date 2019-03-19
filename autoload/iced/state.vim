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

function! iced#state#start_by_name(name) abort " {{{
  if !has_key(s:states, a:name) | return | endif

  let state_def = s:states[a:name]['definition']
  if has_key(state_def, 'start') && type(state_def.start) == v:t_func
    let s:states[a:name]['state'] = state_def.start(s:last_starting_params)
  endif
endfunction " }}}

function! iced#state#start(...) abort " {{{
  let starting_params = get(a:, 1, {})
  let s:last_starting_params = starting_params

  for state_name in s:states_order
    if has_key(s:states, state_name)
          \ && get(s:states[state_name]['definition'], 'lazy', v:false)
      continue
    endif

    call iced#state#start_by_name(state_name)
  endfor
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

function! iced#state#get(name) abort " {{{
  if !has_key(s:states, a:name) | return | endif

  if empty(s:states[a:name]['state'])
        \ && get(s:states[a:name]['definition'], 'lazy', v:false)
    call iced#state#start_by_name(a:name)
  endif

  return s:states[a:name]['state']
endfunction " }}}

call iced#state#define('cache', iced#state#cache#definition())
call iced#state#define('bencode', iced#state#bencode#definition())
call iced#state#define('channel', iced#state#channel#definition())
call iced#state#define('ex_cmd', iced#state#ex_cmd#definition())
call iced#state#define('quickfix', iced#state#quickfix#definition())
call iced#state#define('selector', iced#state#selector#definition())
call iced#state#define('virtual_text', iced#state#virtual_text#definition())

let &cpo = s:save_cpo
unlet s:save_cpo
" vim:fdm=marker:fdl=0
