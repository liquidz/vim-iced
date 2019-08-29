let s:save_cpo = &cpoptions
set cpoptions&vim

let s:saved_view = ''

" p: inspect
" q: quit
" c: continue
" t: trace
" e: eval
" s: stacktrace
" h: here
" i: in
" j: inject
" l: locals
" n: next
" o: out
let s:supported_types = {'n': '', 'c': '', 'q': '', 'j': '' }

" negative value means no limit
let g:iced#debug#value_max_length = get(g:, 'iced#debug#value_max_length', -1)

" a COORDINATES list of '(1 0 2) means:
"  - enter next sexp then `forward-sexp' once,
"  - enter next sexp,
"  - enter next sexp then `forward-sexp' twice.
" c.f. copy from https://github.com/clojure-emacs/cider/blob/c936cdad4c944b716e2842f11c373f69a452c4b2/cider-debug.el#L478-L481
function! s:apply_coordination(coordination) abort
  for c in a:coordination
    " enter next sexp
    normal! l

    let i = c
    while i > 0
      call sexp#move_to_adjacent_element('n', 1, 1, 0, 0)
      let x = strpart(getline('.'), max([col('.')-1, 0]), 6)
      if stridx(x, '#dbg') != 0 && stridx(x, '#break') != 0
        let i = i - 1
      endif
    endwhile
  endfor
endfunction

function! s:ensure_dict(x) abort
  let t = type(a:x)
  if t == v:t_dict
    return a:x
  elseif t == v:t_list
    let result = {}
    for x in a:x
      call extend(result, s:ensure_dict(x))
    endfor
    return result
  else
    return {}
  endif
endfunction

function! s:move_cursor_and_set_highlight(resp) abort
  let nrow = max([a:resp['line'], 1])
  let ncol = max([a:resp['column'], 1])

  if expand('%:p') !=# a:resp['file']
    call iced#di#get('ex_cmd').silent_exe(printf(':edit %s', a:resp['file']))
  endif
  call cursor(nrow, ncol)
  call s:apply_coordination(a:resp['coor'])

  let pos = getcurpos()
  if iced#util#char() ==# '('
    normal! l
    let l = max([len(iced#nrepl#var#cword()), 1])
  else
    let l = max([len(iced#nrepl#var#cword())-1, 0])
  endif
  call iced#highlight#clear()
  call iced#highlight#set_by_line('DiffText', pos[1])
  call iced#highlight#set_by_position('Search', pos[1], pos[2], pos[2]+l)
endfunction

function! s:abbrev_value(s) abort
  return (g:iced#debug#value_max_length > 0 && len(a:s) > g:iced#debug#value_max_length)
       \ ? printf('%s...', strpart(a:s, 0, g:iced#debug#value_max_length))
       \ : a:s
endfunction

let s:debug_info_window_id = -1

function! iced#nrepl#debug#start(resp) abort
  if type(s:saved_view) != v:t_dict
    let s:saved_view = iced#util#save_cursor_position()
  endif

  " NOTE: Disable temporarily.
  "       Enable again at iced#nrepl#debug#quit.
  let &eventignore = 'CursorHold,CursorHoldI,CursorMoved,CursorMovedI'

  let resp = s:ensure_dict(a:resp)
  call s:move_cursor_and_set_highlight(resp)

  let debug_texts = []
  call add(debug_texts, printf(' ::value %s', s:abbrev_value(resp['debug-value'])))
  call add(debug_texts, ' ::locals')

  let locals = resp['locals']
  let ks = map(copy(locals), {_, v -> v[0]})
  let max_key_len = max(map(ks, {_, v -> len(v)})) + 2
  for kv in locals
    let [k, v] = kv
    let v = s:abbrev_value(v)
    call add(debug_texts, printf(' %' . max_key_len . 's: %s', k, v))
  endfor

  if iced#di#get('popup').is_supported()
    if s:debug_info_window_id != -1
      call iced#di#get('popup').close(s:debug_info_window_id)
    endif
    let s:debug_info_window_id = iced#di#get('popup').open(debug_texts, {
         \ 'filetype': 'clojure',
         \ 'line': 'near-cursor',
         \ 'col': col('.'),
         \ 'border': [],
         \ 'borderhighlight': ['Comment'],
         \ 'title': 'Debugging',
         \ 'auto_close': v:false})
  else
    for text in debug_texts
      call iced#buffer#stdout#append(text)
    endfor
  endif

  let input_type = resp['input-type']
  if type(input_type) == v:t_dict
    let ks = filter(sort(keys(input_type)), {_, v -> has_key(s:supported_types, v)})
    let prompt = join(map(ks, {_, k -> printf('(%s)%s', k, input_type[k])}), ', ')
  elseif has_key(resp, 'prompt')
    let prompt = resp['prompt']
  endif

  redraw
  let in = trim(iced#di#get('io').input(prompt . "\n: "))
  if type(input_type) == v:t_dict
    let in = ':'.get(input_type, in, 'quit')
  endif
  call iced#nrepl#op#cider#debug#input(resp['key'], in)
endfunction

function! iced#nrepl#debug#quit() abort
  " NOTE: Enable autocmds
  let &eventignore = ''

  if type(s:saved_view) == v:t_dict
    let s:debug_key = ''
    if !iced#di#get('popup').is_supported()
      call iced#buffer#stdout#append(';; Quit')
    endif
    call iced#highlight#clear()
    call iced#util#restore_cursor_position(s:saved_view)
    let s:saved_view = ''

    if s:debug_info_window_id != -1
      call iced#di#get('popup').close(s:debug_info_window_id)
    endif
    let s:debug_info_window_id = -1
  endif
endfunction

function! s:accept_tapped_value(_, x) abort
  let i = stridx(a:x, ': ')
  if i < 0 | return | endif

  let k = a:x[:i-1]
  call iced#nrepl#debug#browse_tapped(k)
endfunction

function! iced#nrepl#debug#list_tapped() abort
  call iced#promise#call('iced#nrepl#op#iced#list_tapped', [])
        \.then({resp -> has_key(resp, 'error') ? iced#promise#reject(resp['error']) : resp})
        \.then({resp -> map(get(resp, 'tapped', []), {i, v -> printf("%d: %s", i, v)})})
        \.then({candidates -> empty(candidates)
        \                     ? iced#message#warning('not_found')
        \                     : iced#selector({'candidates': candidates,
        \                                      'accept': funcref('s:accept_tapped_value')})})
        \.catch({error -> iced#message#error_str(error)})
endfunction

function! iced#nrepl#debug#browse_tapped(key_str) abort
  let keys = split(a:key_str, '\s\+')
  let keys = map(keys, {_, v ->
        \ (type(v) == v:t_string && match(v, '^\d\+$') == 0) ? str2nr(v) : v})

  let resp = iced#promise#sync('iced#nrepl#op#iced#browse_tapped', [keys])
  if has_key(resp, 'error') | return iced#message#error_str(resp['error']) | endif

  let value = get(resp, 'value', '')
  if empty(value) | return iced#message#warning('not_found') | endif
  call iced#buffer#document#open(value, 'clojure')

  " continue to browse the tapped value in command mode
  let cmd = printf(':IcedBrowseTapped %s ', a:key_str)
  let cmd = substitute(cmd, '\s\+', ' ', 'g')
  call feedkeys(cmd, 'n')
endfunction

function! iced#nrepl#debug#complete_tapped(arg_lead, cmd_line, cursor_pos) abort
  if !iced#nrepl#is_connected() | return '' | endif

  let end = a:cursor_pos - (len(a:arg_lead) + 1)
  let cmd = trim(a:cmd_line[:end])

  let keys = split(cmd, '\s\+')[1:]
  let keys = map(keys, {_, v ->
        \ (type(v) == v:t_string && match(v, '^\d\+$') == 0) ? str2nr(v) : v})
  let resp = iced#promise#sync('iced#nrepl#op#iced#complete_tapped', [keys])
  return join(get(resp, 'complete', []), "\n")
endfunction

function! iced#nrepl#debug#clear_tapped() abort
  call iced#promise#call('iced#nrepl#op#iced#clear_tapped', [])
        \.then({resp -> has_key(resp, 'error')
        \               ? iced#promise#reject(resp['error'])
        \               : resp})
        \.then({_ -> iced#message#info('cleared')})
        \.catch({error -> iced#message#error_str(error)})
endfunction

function! s:toggled_warn_on_reflection(resp) abort
  if !has_key(a:resp, 'value')
    return iced#message#error('unexpected_error', string(a:resp))
  endif
  return iced#message#info('toggle_warn_on_reflection', a:resp['value'])
endfunction

function! iced#nrepl#debug#toggle_warn_on_reflection() abort
  let code = '(set! *warn-on-reflection* (not (true? *warn-on-reflection*)))'
  call iced#nrepl#eval(code, funcref('s:toggled_warn_on_reflection'))
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
