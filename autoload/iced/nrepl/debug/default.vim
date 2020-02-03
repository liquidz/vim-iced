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

""" iced#nrepl#debug#default#apply_coordination {{{
" a COORDINATES list of '(1 0 2) means:
"  - enter next sexp then `forward-sexp' once,
"  - enter next sexp,
"  - enter next sexp then `forward-sexp' twice.
" c.f. copy from https://github.com/clojure-emacs/cider/blob/c936cdad4c944b716e2842f11c373f69a452c4b2/cider-debug.el#L478-L481
function! iced#nrepl#debug#default#apply_coordination(coordination) abort
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
endfunction " }}}

""" iced#nrepl#debug#default#move_cursor_and_set_highlight {{{
function! iced#nrepl#debug#default#move_cursor_and_set_highlight(resp) abort
  let nrow = max([a:resp['line'], 1])
  let ncol = max([a:resp['column'], 1])

  if expand('%:p') !=# a:resp['file']
    call iced#system#get('ex_cmd').silent_exe(printf(':edit %s', a:resp['file']))
  endif
  call cursor(nrow, ncol)
	call iced#nrepl#debug#default#apply_coordination(a:resp['coor'])

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
endfunction " }}}

""" iced#nrepl#debug#default#generate_debug_text {{{
function! s:abbrev_value(s) abort
  return (g:iced#debug#value_max_length > 0 && len(a:s) > g:iced#debug#value_max_length)
       \ ? printf('%s...', strpart(a:s, 0, g:iced#debug#value_max_length))
       \ : a:s
endfunction

function! iced#nrepl#debug#default#generate_debug_text(resp) abort
  let debug_texts = []
  call add(debug_texts, printf(' ::value %s', s:abbrev_value(a:resp['debug-value'])))
  call add(debug_texts, ' ::locals')

  let locals = a:resp['locals']
  let ks = map(copy(locals), {_, v -> v[0]})
  let max_key_len = max(map(ks, {_, v -> len(v)})) + 2
  for kv in locals
    let [k, v] = kv
    let v = s:abbrev_value(v)
    call add(debug_texts, printf(' %' . max_key_len . 's: %s', k, v))
  endfor

  return debug_texts
endfunction " }}}

""" iced#nrepl#debug#default#show_popup {{{
let s:debug_info_window_id = -1

function! iced#nrepl#debug#default#show_popup(texts) abort
  let popup = iced#system#get('popup')
  if s:debug_info_window_id != -1
    call popup.close(s:debug_info_window_id)
  endif
  let s:debug_info_window_id = popup.open(a:texts, {
        \ 'filetype': 'clojure',
        \ 'line': 'near-cursor',
        \ 'col': col('.'),
        \ 'border': [],
        \ 'borderhighlight': ['Comment'],
        \ 'title': 'Debugging',
        \ 'auto_close': v:false})
endfunction " }}}

""" iced#nrepl#debug#default#close_popup {{{
function! iced#nrepl#debug#default#close_popup() abort
  if s:debug_info_window_id != -1
    call iced#system#get('popup').close(s:debug_info_window_id)
  endif
  let s:debug_info_window_id = -1
endfunction " }}}

""" iced#nrepl#debug#default#start {{{
function! iced#nrepl#debug#default#start(resp) abort
  if type(s:saved_view) != v:t_dict
    let s:saved_view = iced#util#save_context()
  endif

  " NOTE: Disable temporarily.
  "       Enable again at iced#nrepl#debug#quit.
  let &eventignore = 'CursorHold,CursorHoldI,CursorMoved,CursorMovedI'

  let resp = s:ensure_dict(a:resp)
  call iced#nrepl#debug#default#move_cursor_and_set_highlight(resp)
  let debug_texts = iced#nrepl#debug#default#generate_debug_text(resp)

  if iced#system#get('popup').is_supported()
    call iced#nrepl#debug#default#show_popup(debug_texts)
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
  let in = trim(iced#system#get('io').input(prompt . "\n: "))
  if type(input_type) == v:t_dict
    let in = ':'.get(input_type, in, 'quit')
  endif
  call iced#nrepl#op#cider#debug#input(resp['key'], in)
endfunction " }}}

""" iced#nrepl#debug#default#quit {{{
function! iced#nrepl#debug#default#quit() abort
  " NOTE: Enable autocmds
  let &eventignore = ''

  if type(s:saved_view) == v:t_dict
    let s:debug_key = ''
    if !iced#system#get('popup').is_supported()
      call iced#buffer#stdout#append(';; Quit')
    endif
    call iced#highlight#clear()
    call iced#util#restore_context(s:saved_view)
    let s:saved_view = ''

    call iced#nrepl#debug#default#close_popup()
  endif
endfunction " }}}

let &cpoptions = s:save_cpo
unlet s:save_cpo
" vim:fdm=marker:fdl=0
