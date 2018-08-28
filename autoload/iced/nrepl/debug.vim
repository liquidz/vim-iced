let s:save_cpo = &cpo
set cpo&vim

let s:saved_view = v:none

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

function! s:apply_coordination(coordination) abort
  for c in a:coordination
    " enter next sexp
    normal! l

    let i = c
    while i > 0
      call sexp#move_to_adjacent_element('n', 1, 1, 0, 0)
      let x = strpart(getline('.'), max([col('.')-1, 1]), 6)
      if stridx(x, '#dbg') != 0 && stridx(x, '#break') != 0
        let i = i - 1
      endif
    endwhile
  endfor
endfunction

function! s:move_cursor_and_set_highlight(resp) abort
  let nrow = max([a:resp['line'], 1])
  let ncol = max([a:resp['column'], 1])

  silent exe printf(':edit %s', a:resp['file'])
  call cursor(nrow, ncol)
  call s:apply_coordination(a:resp['coor'])

  let pos = getcurpos()
  let char = getline('.')[max([col('.')-1, 1])]
  if char ==# '('
    normal! l
    let l = max([len(expand('<cword>')), 1])
  else
    let l = max([len(expand('<cword>'))-1, 0])
  endif
  call iced#highlight#clear()
  call iced#highlight#set_by_position('Search', pos[1], pos[2], pos[2]+l)
endfunction

function! iced#nrepl#debug#start(resp) abort
  if type(s:saved_view) != type({})
    let s:saved_view = iced#util#save_cursor_position()
  endif

  call s:move_cursor_and_set_highlight(a:resp)

  call iced#buffer#stdout#append(" \n;; Debugging")
  call iced#buffer#stdout#append(printf('::value %s', a:resp['debug-value']))
  call iced#buffer#stdout#append('::locals')

  let locals = a:resp['locals']
  let ks = map(copy(locals), {_, v -> v[0]})
  let max_key_len = max(map(ks, {_, v -> len(v)})) + 2
  for kv in locals
    let [k, v] = kv
    call iced#buffer#stdout#append(printf('%' . max_key_len . 's: %s', k, v))
  endfor

  let input_type = a:resp['input-type']
  if type(input_type) == type({})
    let ks = filter(sort(keys(input_type)), {_, v -> has_key(s:supported_types, v)})
    let prompt = join(map(ks, {_, k -> printf('(%s)%s', k, input_type[k])}), ', ')
  elseif has_key(a:resp, 'prompt')
    let prompt = a:resp['prompt']
  endif

  redraw
  let in = trim(input(prompt . "\n: "))
  if type(input_type) == type({})
    let in = ':'.get(input_type, in, 'quit')
  endif
  call iced#nrepl#cider#debug#input(a:resp['key'], in)
endfunction

function! iced#nrepl#debug#quit() abort
  if type(s:saved_view) == type({})
    let s:debug_key = v:none
    call iced#buffer#stdout#append(';; Quit')
    call iced#highlight#clear()
    call iced#util#restore_cursor_position(s:saved_view)
    let s:saved_view = v:none
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
