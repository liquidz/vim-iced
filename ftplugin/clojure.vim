if exists('g:loaded_vim_iced')
  finish
endif
let g:loaded_vim_iced = 1

let s:save_cpo = &cpo
set cpo&vim

"" Commands {{{
command! -nargs=? IcedConnect          call iced#nrepl#connect(<q-args>)
command!          IcedDisconnect       call iced#nrepl#disconnect()
command!          IcedInterrupt        call iced#nrepl#interrupt()

command! -nargs=? -complete=custom,iced#nrepl#cljs#env_complete
    \ IcedStartCljsRepl    call iced#nrepl#cljs#repl(<q-args>)
command!          IcedQuitCljsRepl     call iced#nrepl#cljs#quit()

command! -nargs=1 IcedEval             call iced#nrepl#eval#code(<q-args>)
command! -nargs=1 IcedEvalRepl         call iced#nrepl#eval#repl(<q-args>)
command!          IcedRequire          call iced#nrepl#ns#require()
command!          IcedRequireAll       call iced#nrepl#ns#require_all()
command! -nargs=? IcedUndef            call iced#nrepl#eval#undef(<q-args>)

command!          IcedTestNs           call iced#nrepl#test#ns()
command!          IcedTestAll          call iced#nrepl#test#all()
command!          IcedTestRedo         call iced#nrepl#test#redo()
command!          IcedTestUnderCursor  call iced#nrepl#test#under_cursor()

command!          IcedBufferOpen       call iced#buffer#open()
command!          IcedBufferClear      call iced#buffer#clear()

command! -nargs=? IcedDefJump          call iced#nrepl#jump#jump(<q-args>)
command!          IcedDefBack          call iced#nrepl#jump#back()

command! -nargs=? IcedDocumentOpen     call iced#nrepl#document#open(<q-args>)
command!          IcedEchoFormDocument call iced#nrepl#document#echo_current_form()
command! -nargs=? IcedGrimoireOpen     call iced#grimoire#open(<q-args>)

command!          IcedSlurp            call iced#paredit#deep_slurp()
command!          IcedBarf             call iced#paredit#barf()
command!          IcedFormat           call iced#format#form()
command!          IcedToggleSrcAndTest call iced#nrepl#ns#transition#toggle_src_and_test()

command!          IcedCleanNs          call iced#nrepl#refactor#clean_ns()
command! -nargs=? IcedAddMissing       call iced#nrepl#refactor#add_missing(<q-args>)
"" }}}

"" Key mappings {{{
nnoremap <silent> <Plug>(iced_connect)             :<C-u>IcedConnect<CR>
nnoremap <silent> <Plug>(iced_disconnect)          :<C-u>IcedDisconnect<CR>
nnoremap <silent> <Plug>(iced_interrupt)           :<C-u>IcedInterrupt<CR>

nnoremap <silent> <Plug>(iced_start_cljs_repl)     :<C-u>IcedStartCljsRepl<CR>
nnoremap <silent> <Plug>(iced_quit_cljs_repl)      :<C-u>IcedQuitCljsRepl<CR>

nnoremap <silent> <Plug>(iced_eval)                :<C-u>set opfunc=iced#operation#eval<CR>g@
nnoremap <silent> <Plug>(iced_macroexpand)         :<C-u>set opfunc=iced#operation#macroexpand<CR>g@
nnoremap <silent> <Plug>(iced_macroexpand_1)       :<C-u>set opfunc=iced#operation#macroexpand_1<CR>g@
nnoremap <silent> <Plug>(iced_require)             :<C-u>IcedRequire<CR>
nnoremap <silent> <Plug>(iced_require_all)         :<C-u>IcedRequireAll<CR>
nnoremap <silent> <Plug>(iced_undef)               :<C-u>IcedUndef<CR>

nnoremap <silent> <Plug>(iced_test_ns)             :<C-u>IcedTestNs<CR>
nnoremap <silent> <Plug>(iced_test_all)            :<C-u>IcedTestAll<CR>
nnoremap <silent> <Plug>(iced_test_redo)           :<C-u>IcedTestRedo<CR>
nnoremap <silent> <Plug>(iced_test_under_cursor)   :<C-u>IcedTestUnderCursor<CR>

nnoremap <silent> <Plug>(iced_buffer_open)         :<C-u>IcedBufferOpen<CR>
nnoremap <silent> <Plug>(iced_buffer_clear)        :<C-u>IcedBufferClear<CR>

nnoremap <silent> <Plug>(iced_def_jump)            :<C-u>IcedDefJump<CR>
nnoremap <silent> <Plug>(iced_def_back)            :<C-u>IcedDefBack<CR>

nnoremap <silent> <Plug>(iced_document_open)       :<C-u>IcedDocumentOpen<CR>
nnoremap <silent> <Plug>(iced_echo_form_document)  :<C-u>IcedEchoFormDocument<CR>
nnoremap <silent> <Plug>(iced_grimoire_open)       :<C-u>IcedGrimoireOpen<CR>

nnoremap <silent> <Plug>(iced_slurp)               :<C-u>IcedSlurp<CR>
nnoremap <silent> <Plug>(iced_barf)                :<C-u>IcedBarf<CR>
nnoremap <silent> <Plug>(iced_format)              :<C-u>IcedFormat<CR>
nnoremap <silent> <Plug>(iced_toggle_src_and_test) :<C-u>IcedToggleSrcAndTest<CR>

nnoremap <silent> <Plug>(iced_clean_ns)            :<C-u>IcedCleanNs<CR>
nnoremap <silent> <Plug>(iced_add_missing)         :<C-u>IcedAddMissing<CR>
"" }}}

"" Auto commands {{{
aug vim_iced_initial_setting
  au!
  au FileType clojure setl omnifunc=iced#complete#omni
  au VimLeave *       call iced#nrepl#disconnect()
aug END
"" }}}

"" Default mappings {{{
function! s:default_key_mappings() abort
  if !hasmapto('<Plug>(iced_connect)')
    silent! nmap <buffer> <Leader>' <Plug>(iced_connect)
  endif

  if !hasmapto('<Plug>(iced_interrupt)')
    silent! nmap <buffer> <Leader>eq <Plug>(iced_interrupt)
  endif

  if !hasmapto('<Plug>(iced_eval)')
    silent! nmap <buffer> <Leader>ei <Plug>(iced_eval)<Plug>(sexp_inner_element)``
    silent! nmap <buffer> <Leader>ee <Plug>(iced_eval)<Plug>(sexp_outer_list)``
    silent! nmap <buffer> <Leader>et <Plug>(iced_eval)<Plug>(sexp_outer_top_list)``
  endif

  if !hasmapto('<Plug>(iced_require)')
    silent! nmap <buffer> <Leader>eb <Plug>(iced_require)
  endif

  if !hasmapto('<Plug>(iced_require_all)')
    silent! nmap <buffer> <Leader>eB <Plug>(iced_require_all)
  endif

  if !hasmapto('<Plug>(iced_undef)')
    silent! nmap <buffer> <Leader>eu <Plug>(iced_undef)
  endif

  if !hasmapto('<Plug>(iced_macroexpand)')
    silent! nmap <buffer> <Leader>ma <Plug>(iced_macroexpand)<Plug>(sexp_outer_list)``
  endif

  if !hasmapto('<Plug>(iced_macroexpand_1)')
    silent! nmap <buffer> <Leader>m1 <Plug>(iced_macroexpand_1)<Plug>(sexp_outer_list)``
  endif

  if !hasmapto('<Plug>(iced_test_under_cursor)')
    silent! nmap <buffer> <Leader>tt <Plug>(iced_test_under_cursor)
  endif

  if !hasmapto('<Plug>(iced_test_ns)')
    silent! nmap <buffer> <Leader>tn <Plug>(iced_test_ns)
  endif

  if !hasmapto('<Plug>(iced_test_all)')
    silent! nmap <buffer> <Leader>tp <Plug>(iced_test_all)
  endif

  if !hasmapto('<Plug>(iced_test_redo)')
    silent! nmap <buffer> <Leader>tr <Plug>(iced_test_redo)
  endif

  if !hasmapto('<Plug>(iced_buffer_open)')
    silent! nmap <buffer> <Leader>ss <Plug>(iced_buffer_open)
  endif

  if !hasmapto('<Plug>(iced_def_jump)')
    silent! nmap <buffer> <C-]> <Plug>(iced_def_jump)
  endif

  if !hasmapto('<Plug>(iced_def_back)')
    silent! nmap <buffer> <C-t> <Plug>(iced_def_back)
  endif

  if !hasmapto('<Plug>(iced_clean_ns)')
    silent! nmap <buffer> <Leader>rcn <Plug>(iced_clean_ns)
  endif

  if !hasmapto('<Plug>(iced_add_missing)')
    silent! nmap <buffer> <Leader>ram <Plug>(iced_add_missing)
  endif

  if !hasmapto('<Plug>(iced_format)')
    silent! nmap <buffer> == <Plug>(iced_format)
  endif

  if !hasmapto('<Plug>(iced_document_open)')
    silent! nmap <buffer> K <Plug>(iced_document_open)
  endif

  if !hasmapto('<Plug>(iced_grimoire_open)')
    silent! nmap <buffer> <Leader>hg <Plug>(iced_grimoire_open)
  endif
endfunction

if exists('g:iced_enable_default_key_mappings')
    \ && g:iced_enable_default_key_mappings
  silent! call s:default_key_mappings()
  aug iced_default_key_mappings
    au!
    au FileType clojure call s:default_key_mappings()
  aug END
endif
"" }}}

"" Signs {{{
sign define iced_err text=>> texthl=ErrorMsg
"" }}}

let &cpo = s:save_cpo
unlet s:save_cpo

