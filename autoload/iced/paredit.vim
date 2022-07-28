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
        " NOTE: `%` may be matched to parentheses in comment block without matchit.vim
        " NOTE: <Plug>(sexp_move_to_next_bracket) changes jumplist
        call sexp#move_to_nearest_bracket('n', 1)
        let end_pos = getcurpos()

        if s:is_in_range(pos, start_pos, end_pos)
          " select end_pos to start_pos
          call setpos('.', end_pos)
          silent exe 'keepjumps normal! v'
          call setpos('.', start_pos)
          " NOTE: `0` is to wrap top level tag literal
          silent exe 'keepjumps normal! 0y'

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
      silent exe 'keepjumps normal! vaby'
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
    keepjumps silent normal! va(y
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

" from vim-sexp
function! s:get_visual_marks() abort
    return [getpos("'<"), getpos("'>")]
endfunction

function! s:set_visual_marks(marks) abort
    call setpos("'<", a:marks[0])
    call setpos("'>", a:marks[1])
endfunction

" Return visually selected text without changing selection state and registers
function! s:get_visual_selection_and_pos() abort
    let reg_save = @@
    silent normal! y
    let code = @@
    let pos = getcurpos()
    let @@ = reg_save
    silent normal! gv
    return {'code': code, 'curpos': pos}
endfunction

function! s:select_top_list(top_code) abort
    let reg_save = @@
    try
        while (v:true)
            call sexp#select_current_list('v', 0, 1)
            let current_marks = s:get_visual_marks()

            call sexp#docount(2, 'sexp#select_current_list', 'v', 0, 1)
            let next_code = get(s:get_visual_selection_and_pos(), 'code', '')

            if (next_code ==# a:top_code) | break | endif
        endwhile
        call s:set_visual_marks(current_marks)
        normal! gv
    finally
        let @@ = reg_save
    endtry
endfunction

function! s:select_current_top_list() abort
  let current_line = line('.')
  let start_line = search('^\S', 'bW')

  call search('(', 'cW')
  silent normal! %
  let end_pos = getcurpos()

  if start_line > current_line || current_line > end_pos[1]
    return ''
  endif

  call cursor(start_line, 1)
  silent normal! v
  call cursor(end_pos[1], end_pos[2])
endfunction

function! iced#paredit#get_top_list_in_comment() abort
    let view = winsaveview()
    let curpos = getpos('.')

    " NOTE: `sexp#select_current_top_list` cannot correctly select codes
    "       including reader conditionals like below
    "       > #?(:clj :foo
    "       >    :cljs :bar)
    call s:select_current_top_list()
    let top_code = get(s:get_visual_selection_and_pos(), 'code', '')

    if (stridx(top_code, '(comment') == 0)
        " Select up one by one if the top list is a (comment ...) form
        execute "normal! \<Esc>"
        call setpos('.', curpos)
        call s:select_top_list(top_code)
    endif
    let ret = s:get_visual_selection_and_pos()
    execute "normal! \<Esc>"
    call winrestview(view)
    return ret
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
