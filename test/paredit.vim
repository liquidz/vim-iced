let s:suite  = themis#suite('iced.paredit')
" let s:assert = themis#helper('assert')
" let s:scope = themis#helper('scope')
" let s:buf = themis#helper('iced_buffer')
" let s:ch = themis#helper('iced_channel')
" let s:funcs = s:scope.funcs('autoload/iced/nrepl.vim')
"
" let g:iced_enable_clj_kondo_analysis = v:false
" let g:iced_cache_directory = ''
"
" function! s:format_code_relay(msg) abort
"   if a:msg['op'] ==# 'iced-format-code-with-indents'
"     return {'status': ['done'], 'formatted': a:msg['code']}
"   elseif a:msg['op'] ==# 'iced-set-indentation-rules'
"     return {'status': ['done']}
"   elseif a:msg['op'] ==# 'ns-aliases'
"     return {'status': ['done'], 'ns-aliases': {}}
"   else
"     return {'status': ['done']}
"   endif
" endfunction
"
" function! s:suite.deep_slurp_test() abort
"   call s:ch.mock({
"      \ 'status_value': 'open',
"      \ 'relay': funcref('s:format_code_relay'),
"      \ })
"
"   call s:buf.start_dummy(['(foo (|bar)) baz'])
"   cal iced#paredit#deep_slurp()
"   call s:assert.equals(s:buf.get_texts(), '(foo (bar) baz)')
"
"   cal iced#paredit#deep_slurp()
"   call s:assert.equals(s:buf.get_texts(), '(foo (bar baz))')
"
"   call s:buf.stop_dummy()
" endfunction
"
" function! s:suite.barf_test() abort
"   call s:buf.start_dummy(['(foo (|bar baz))'])
"
"   cal iced#paredit#barf()
"   call s:assert.equals(s:buf.get_texts(), '(foo (bar) baz)')
"
"   call s:buf.stop_dummy()
" endfunction
"
" function! s:suite.get_current_top_object_test() abort
"   call s:buf.start_dummy([
"        \ '(foo',
"        \ ' (bar|))',
"        \ ])
"   let res = iced#paredit#get_current_top_object()
"   call s:assert.equals(res['code'], "(foo\n (bar))")
"   call s:buf.stop_dummy()
" endfunction
"
" function! s:suite.get_current_top_object_with_blank_line_test() abort
"   call s:buf.start_dummy([
"        \ '(foo',
"        \ '|',
"        \ ' (bar))',
"        \ ])
"   let res = iced#paredit#get_current_top_object()
"   call s:assert.equals(res['code'], "(foo\n\n (bar))")
"   call s:buf.stop_dummy()
" endfunction
"
" function! s:suite.get_current_top_object_with_tag_test() abort
"   call s:buf.start_dummy([
"        \ '#?(:clj',
"        \ '   (foo (bar|)))',
"        \ ])
"   let res = iced#paredit#get_current_top_object()
"   call s:assert.equals(res['code'], "#?(:clj\n   (foo (bar)))")
"   call s:buf.stop_dummy()
" endfunction
"
" function! s:suite.get_current_top_object_with_comment_test() abort
"   call s:buf.start_dummy([
"        \ '(foo',
"        \ ' ;; baz)',
"        \ ' (bar|))',
"        \ ])
"   let res = iced#paredit#get_current_top_object()
"   call s:assert.equals(res['code'], "(foo\n ;; baz)\n (bar))")
"   call s:buf.stop_dummy()
" endfunction
"
" function! s:suite.move_to_current_element_head_test() abort
"   call s:buf.start_dummy(['(foo (bar (baz|)))'])
"   call s:assert.equals(col('.'), 15)
"   call s:assert.not_equals(iced#paredit#move_to_current_element_head(), 0)
"   call s:assert.equals(col('.'), 11)
"   call s:buf.stop_dummy()
"
"   call s:buf.start_dummy(['(foo (bar |(baz)))'])
"   call s:assert.equals(col('.'), 11)
"   call s:assert.not_equals(iced#paredit#move_to_current_element_head(), 0)
"   call s:assert.equals(col('.'), 11)
"   call s:buf.stop_dummy()
" endfunction
"
" function! s:suite.move_to_current_element_head_not_form_test() abort
"   call s:buf.start_dummy(['(foo (bar (baz)))', '|'])
"   let pos = getcurpos()
"   call s:assert.equals(iced#paredit#move_to_current_element_head(), 0)
"   call s:assert.equals(getcurpos(), pos)
"   call s:buf.stop_dummy()
" endfunction
"
" function! s:suite.move_to_parent_element_test() abort
"   call s:buf.start_dummy([
"        \ '(foo (bar (baz|))',
"        \ ])
"   call s:assert.equals(col('.'), 15)
"   call iced#paredit#move_to_parent_element()
"   call s:assert.equals(col('.'), 6)
"   call s:buf.stop_dummy()
"
"   call s:buf.start_dummy([
"        \ '(do (foo bar) (baz|))',
"        \ ])
"   call iced#paredit#move_to_parent_element()
"   call s:assert.equals(col('.'), 1)
"   call s:buf.stop_dummy()
" endfunction
"
" function! s:suite.move_to_parent_element_no_parent_test() abort
"   call s:buf.start_dummy([
"        \ '(foo| (bar (baz))',
"        \ ])
"   let pos = getcurpos()
"   call iced#paredit#move_to_parent_element()
"   call s:assert.equals(getcurpos(), pos)
"   call s:buf.stop_dummy()
" endfunction
"
" function! s:suite.find_parent_form_raw_test() abort
"   call s:buf.start_dummy([
"       \ '(foo',
"       \ ' (bar',
"       \ '  (baz|)))',
"       \ ])
"   let pos = getcurpos()
"
"   let res = iced#paredit#find_parent_form_raw(['bar'])
"   call s:assert.equals(res['code'], "(bar\n  (baz))")
"   call s:assert.equals([res['curpos'][1], res['curpos'][2]], [2, 2])
"
"   call setpos('.', pos)
"   let res = iced#paredit#find_parent_form_raw(['foo'])
"   call s:assert.equals(res['code'], "(foo\n (bar\n  (baz)))")
"   call s:assert.equals([res['curpos'][1], res['curpos'][2]], [1, 1])
"
"   call setpos('.', pos)
"   let res = iced#paredit#find_parent_form_raw(['foo', 'bar', 'baz'])
"   call s:assert.equals(res['code'], '(baz)')
"   call s:assert.equals([res['curpos'][1], res['curpos'][2]], [3, 3])
"
"   call setpos('.', pos)
"   let res = iced#paredit#find_parent_form_raw(['non_existing'])
"   call s:assert.equals(res, {})
"
"   call s:buf.stop_dummy()
" endfunction
"
" function! s:suite.get_current_top_object_test() abort
"   call s:buf.start_dummy([
"        \ '(foo',
"        \ ' (bar|))',
"        \ ])
"   let res = iced#paredit#get_current_top_object()
"   call s:assert.equals(res['code'], "(foo\n (bar))")
"   call s:buf.stop_dummy()
"
"   " with meta
"   call s:buf.start_dummy([
"        \ '#tag1/name (foo',
"        \ ' (bar|))',
"        \ ])
"   let res = iced#paredit#get_current_top_object()
"   call s:assert.equals(res['code'], "#tag1/name (foo\n (bar))")
"   call s:buf.stop_dummy()
" endfunction
"
" function! s:suite.get_current_top_object_vector_test() abort
"   call s:buf.start_dummy([
"       \ '[foo',
"       \ ' [bar|]]',
"       \ ])
"   let res = iced#paredit#get_current_top_object()
"   call s:assert.equals(res, {})
"   let res = iced#paredit#get_current_top_object('[', ']')
"   call s:assert.equals(res['code'], "[foo\n [bar]]")
"   call s:buf.stop_dummy()
"
"   " with meta
"   call s:buf.start_dummy([
"       \ '#tag2/name [foo',
"       \ ' [bar|]]',
"       \ ])
"   let res = iced#paredit#get_current_top_object('[', ']')
"   call s:assert.equals(res['code'], "#tag2/name [foo\n [bar]]")
"   call s:buf.stop_dummy()
" endfunction
"
" function! s:suite.get_current_top_object_vector_test() abort
"   call s:buf.start_dummy([
"       \ '{:foo',
"       \ ' {:bar 123|}}',
"       \ ])
"   let res = iced#paredit#get_current_top_object()
"   call s:assert.equals(res, {'code': '', 'curpos': []})
"   let res = iced#paredit#get_current_top_object('{', '}')
"   call s:assert.equals(res['code'], "{:foo\n {:bar 123}}")
"   call s:buf.stop_dummy()
"
"   " with meta
"   call s:buf.start_dummy([
"       \ '#tag3/name {:foo',
"       \ ' {:bar 123|}}',
"       \ ])
"   let res = iced#paredit#get_current_top_object('{', '}')
"   call s:assert.equals(res['code'], "#tag3/name {:foo\n {:bar 123}}")
"   call s:buf.stop_dummy()
" endfunction
"
" function! s:suite.get_current_top_something_test() abort
"   " list
"   call s:buf.start_dummy([
"       \ '(:foo',
"       \ ' {:bar 123|})',
"       \ ])
"   let res = iced#paredit#get_current_top_something()
"   call s:assert.equals(res['code'], "(:foo\n {:bar 123})")
"   call s:buf.stop_dummy()
"
"   " vector
"   call s:buf.start_dummy([
"       \ '[:foo',
"       \ ' {:bar 123|}]',
"       \ ])
"   let res = iced#paredit#get_current_top_something()
"   call s:assert.equals(res['code'], "[:foo\n {:bar 123}]")
"   call s:buf.stop_dummy()
"
"   " map
"   call s:buf.start_dummy([
"       \ '{:foo',
"       \ ' {:bar 123|}}',
"       \ ])
"   let res = iced#paredit#get_current_top_something()
"   call s:assert.equals(res['code'], "{:foo\n {:bar 123}}")
"   call s:buf.stop_dummy()
" endfunction
