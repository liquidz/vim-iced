let s:suite  = themis#suite('iced.paredit')
let s:assert = themis#helper('assert')

" util {{{
function! s:start_dummy_buffer(lines) abort
  vnew
  setl buftype=nofile
  setl nobuflisted
 
  let i = 1
  let cursor_pos = [1, 1]
  for line in a:lines
    let n = stridx(line, '|')
    if n != -1
      let cursor_pos = [i, n+1]
    endif
    call setline(i, substitute(line, '|', '', 'g'))
    let i = i+1
  endfor

  call cursor(cursor_pos[0], cursor_pos[1])
endfunction

function! s:get_dummy_buffer_text() abort
  return trim(join(getline(line('^'), line('$')), ''))
endfunction

function! s:stop_dummy_buffer() abort
  exe ':q'
endfunction
" }}}

function! s:suite.deep_slurp_test() abort
  call s:start_dummy_buffer(['(foo (|bar)) baz'])
  cal iced#paredit#deep_slurp()
  call s:assert.equals(s:get_dummy_buffer_text(), '(foo (bar) baz)')

  cal iced#paredit#deep_slurp()
  call s:assert.equals(s:get_dummy_buffer_text(), '(foo (bar baz))')

  call s:stop_dummy_buffer()
endfunction

function! s:suite.barf_test() abort
  call s:start_dummy_buffer(['(foo (|bar baz))'])

  cal iced#paredit#barf()
  call s:assert.equals(s:get_dummy_buffer_text(), '(foo (bar) baz)')

  call s:stop_dummy_buffer()
endfunction

function! s:suite.get_current_top_list_test() abort
  call s:start_dummy_buffer([
        \ '(foo',
        \ ' (bar|))',
        \ ])
  let res = iced#paredit#get_current_top_list()
  call s:assert.equals(res['code'], "(foo\n (bar))")
  call s:stop_dummy_buffer()
endfunction

function! s:suite.get_current_top_list_with_blank_line_test() abort
  call s:start_dummy_buffer([
        \ '(foo',
        \ '|',
        \ ' (bar))',
        \ ])
  let res = iced#paredit#get_current_top_list()
  call s:assert.equals(res['code'], "(foo\n\n (bar))")
  call s:stop_dummy_buffer()
endfunction

function! s:suite.get_current_top_list_with_tag_test() abort
  call s:start_dummy_buffer([
        \ '#?(:clj',
        \ '   (foo (bar|)))',
        \ ])
  let res = iced#paredit#get_current_top_list()
  call s:assert.equals(res['code'], "#?(:clj\n   (foo (bar)))")
  call s:stop_dummy_buffer()
endfunction
