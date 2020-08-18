let s:save_cpo = &cpo
set cpo&vim

let g:iced#paredit#slurp_max_depth = get(g:, 'iced#paredit#slurp_max_depth', 5)

function! s:is_pos_before(pos1, pos2) abort
  if a:pos1[0] < a:pos2[0]
    return v:true
  elseif a:pos1[0] == a:pos2[0] && a:pos1[1] < a:pos2[1]
    return v:true
  endif
  return v:false
endfunction

function! s:slurp(current_view, depth) abort
  if a:depth > g:iced#paredit#slurp_max_depth
    return iced#message#error('too_deep_to_slurp')
  endif

  let before = getcurpos()
  call sexp#stackop('n', 1, 1)
  let after = getcurpos()

  if before == after
    call sexp#move_to_nearest_bracket('n', 0)
    call s:slurp(a:current_view, a:depth + 1)
  else
    call iced#format#minimal()
    call winrestview(a:current_view)
  endif
endfunction

function! iced#paredit#deep_slurp() abort
  call s:slurp(winsaveview(), 1)
endfunction

function! iced#paredit#barf() abort
  let view = winsaveview()
  call sexp#stackop('n', 1, 0)
  call winrestview(view)
endfunction

function! iced#paredit#move_to_prev_top_element() abort
  call sexp#move_to_adjacent_element('n', 0, 0, 0, 1)
endfunction

function! iced#paredit#move_to_current_element_head() abort
  if iced#util#char() ==# '('
    return col('.')
  else
    let view = winsaveview()
    while v:true
      let start = searchpos('(', 'bWn')
      let end = searchpos(')', 'bWn')

      if start == [0, 0] && end == [0, 0]
        call winrestview(view)
        return 0
      elseif start == [0, 0] && end != [0, 0]
        call winrestview(view)
        return 0
      elseif start != [0, 0] && end == [0, 0]
        call cursor(start[0], start[1])
        return col('.')
      elseif start != [0, 0] && end != [0, 0]
        if s:is_pos_before(start, end)
          call cursor(end[0], end[1])
          silent normal! %
        else
          call cursor(start[0], start[1])
          return col('.')
        endif
      endif
    endwhile
  endif
endfunction

function! iced#paredit#move_to_parent_element() abort
  let view = winsaveview()
  if iced#paredit#move_to_current_element_head() == 0 || col('.') == 1
    call winrestview(view)
    return 0
  endif

  silent normal! h
  if iced#paredit#move_to_current_element_head() == 0
    call winrestview(view)
    return 0
  endif
  return col('.')
endfunction

function! s:is_in_range(current_pos, start_pos, end_pos) abort
  return (a:current_pos[1] == a:start_pos[1] && a:start_pos[2] <= a:current_pos[2])
        \ || (a:current_pos[1] == a:end_pos[1] && a:current_pos[2] <= a:end_pos[2])
        \ || (a:start_pos[1] <= a:current_pos[1] && a:current_pos[1] <= a:end_pos[1])
endfunction

function! iced#paredit#get_current_top_object_raw(...) abort
  let open_char = get(a:, 1, '(')
  let close_char = get(a:, 2, ')')
  let pos = getcurpos()
  let result = {'code': '', 'curpos': []}

  try
    while v:true
      let line = getline('.')

      if !empty(line) && substitute(line, '^#[^\(\[\{ ]\+ \?', '', '')[0] ==# open_char
        " Found a top level object
        let start_pos = getcurpos()
        let start_pos[2] = stridx(line, open_char) + 1

        call setpos('.', start_pos)
        " move to pair
        silent normal! %
        let end_pos = getcurpos()

        if s:is_in_range(pos, start_pos, end_pos)
          call setpos('.', start_pos)
          " NOTE: `o0y` is to wrap top level tag literal
          silent exe printf('normal! va%so0y', open_char)

          let result = {
               \ 'code': @@,
               \ 'curpos': start_pos,
               \ }
        endif

        break
      endif

      if line('.') == 1 | break | endif
      " Move cursor up
      silent normal! k
    endwhile
  finally
    silent exe "normal! \<Esc>"
  endtry

  return result
endfunction

function! iced#paredit#get_current_top_object(...) abort
  let view = winsaveview()
  let reg_save = @@

  try
    return call('iced#paredit#get_current_top_object_raw', a:000)
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

function! iced#paredit#get_current_top_something() abort
  let res = iced#paredit#get_current_top_object('(', ')')
  if !empty(get(res, 'code')) | return res | endif

  let res = iced#paredit#get_current_top_object('{', '}')
  if !empty(get(res, 'code')) | return res | endif

  return iced#paredit#get_current_top_object('[', ']')
endfunction

function! iced#paredit#find_parent_form_raw(prefixes) abort
  let reg_save = @@
  let prefixes = map(copy(a:prefixes), {_, s -> printf('(%s', s)})

  try
    while v:true
      let @@ = ''
      silent exe 'normal! vaby'
      if empty(@@) | break | endif

      let code = @@
      for p in prefixes
        if stridx(code, p) == 0
          return {'code': code, 'curpos': getcurpos()}
        endif
      endfor

      " not found
      if col('.') == 1 || stridx(getline('.'), '#') == 0
        return {}
      endif

      silent normal! h
    endwhile
  finally
    let @@ = reg_save
    silent exe "normal! \<Esc>"
  endtry

  return {}
endfunction

function! iced#paredit#get_outer_list_raw() abort
  try
    silent normal! va(y
  finally
    silent exe "normal! \<Esc>"
  endtry
  return @@
endfunction

function! iced#paredit#get_outer_list() abort
  let view = winsaveview()
  let reg_save = @@
  let code = ''

  try
    let code = iced#paredit#get_outer_list_raw()
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry

  return code
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
