if exists('g:loaded_vim_iced')
  finish
endif
let g:loaded_vim_iced = 1
let g:vim_iced_version = 10302
let g:vim_iced_home = expand('<sfile>:p:h:h')
" NOTE: https://github.com/vim/vim/commit/162b71479bd4dcdb3a2ef9198a1444f6f99e6843
"       Add functions for defining and placing signs.
"       Introduce a group name to avoid different plugins using the same signs.
let g:vim_iced_required_vim_version = '8.1.0614'
let g:vim_iced_required_nvim_version = '0.4'

let s:required_version = has('nvim')
      \ ? has(printf('nvim-%s', g:vim_iced_required_nvim_version))
      \ : has(printf('patch-%s', g:vim_iced_required_vim_version))
if !s:required_version
  echoerr printf('vim-iced requires Vim %s+ or Neovim %s+',
        \ g:vim_iced_required_vim_version,
        \ g:vim_iced_required_nvim_version,
        \ )
  finish
endif

let s:save_cpo = &cpoptions
set cpoptions&vim

scriptencoding utf-8

if !exists('g:iced_enable_auto_document')
  let g:iced_enable_auto_document = 'none'
endif

if !exists('g:iced_enable_popup_document')
  let g:iced_enable_popup_document = 'every'
endif

if !exists('g:iced_max_distance_for_auto_document')
  let g:iced_max_distance_for_auto_document = 2
endif

if !exists('g:iced_enable_enhanced_cljs_completion')
  let g:iced_enable_enhanced_cljs_completion = v:true
endif

if !exists('g:iced_enable_enhanced_definition_extraction')
  let g:iced_enable_enhanced_definition_extraction = v:true
endif

"" Commands {{{
command! -nargs=? IcedConnect               call iced#repl#connect('nrepl', <q-args>)
command! -nargs=1 IcedConnectSocketRepl     call iced#repl#connect('socket_repl', <q-args>)
command! -nargs=1 IcedConnectPrepl          call iced#repl#connect('prepl', <q-args>)
command!          IcedDisconnect            call iced#repl#execute('disconnect')
command!          IcedReconnect             call iced#nrepl#reconnect()
command!          IcedInterrupt             call iced#nrepl#interrupt()
command!          IcedInterruptAll          call iced#nrepl#interrupt_all()
command! -nargs=? -complete=custom,iced#repl#instant_connect_complete
      \ IcedInstantConnect call iced#repl#instant_connect(<q-args>) "iced#nrepl#connect#instant()

command!          IcedJackIn                call iced#nrepl#connect#jack_in()

command! -nargs=? IcedCljsRepl              call iced#nrepl#cljs#start_repl(<q-args>)
command! -nargs=+ -complete=custom,iced#nrepl#cljs#env_complete
      \ IcedStartCljsRepl    call iced#nrepl#cljs#start_repl_via_env(<f-args>)
command!          IcedQuitCljsRepl          call iced#nrepl#cljs#stop_repl_via_env()
command!          IcedCycleSession          call iced#nrepl#cljs#cycle_session()

command! -nargs=1 IcedEval                  call iced#repl#execute('eval_code', <q-args>, {'ignore_session_validity': v:true})
command!          IcedEvalNs                call iced#nrepl#eval#ns()
command! -range   IcedEvalVisual            call iced#nrepl#eval#visual()
command!          IcedRequire               call iced#repl#execute('load_current_file')
command!          IcedRequireAll            call iced#nrepl#ns#reload_all()
command! -nargs=? IcedUndef                 call iced#nrepl#eval#undef(<q-args>)
command! -nargs=? IcedUndefAllInNs          call iced#nrepl#eval#undef_all_in_ns(<q-args>)
command!          IcedEvalOuterTopList      call iced#repl#execute('eval_outer_top_list')
command!          IcedEvalAtMark            call iced#repl#execute('eval_at_mark', nr2char(getchar()))
command!          IcedPrintLast             call iced#nrepl#eval#print_last()
command!          IcedMacroExpandOuterList  call iced#nrepl#macro#expand_outer_list()
command!          IcedMacroExpand1OuterList call iced#nrepl#macro#expand_1_outer_list()

command!          IcedTestNs                call iced#nrepl#test#ns()
command!          IcedTestAll               call iced#nrepl#test#all()
command!          IcedTestRedo              call iced#nrepl#test#redo()
command!          IcedTestUnderCursor       call iced#nrepl#test#under_cursor()
command!          IcedTestRerunLast         call iced#nrepl#test#rerun_last()
command! -nargs=? IcedTestSpecCheck         call iced#nrepl#test#spec_check(<q-args>)
command!          IcedTestBufferOpen        call iced#buffer#error#open()

command!          IcedStdoutBufferOpen      call iced#buffer#stdout#open()
command!          IcedStdoutBufferClear     call iced#buffer#stdout#clear()
command!          IcedStdoutBufferClose     call iced#buffer#stdout#close()

command! -nargs=? IcedDefJump               call iced#nrepl#navigate#jump_to_def(<q-args>)
command! -nargs=1 -complete=custom,iced#nrepl#navigate#ns_complete
      \ IcedOpenNs                          call iced#nrepl#navigate#open_ns('e', <q-args>)

command! -nargs=? IcedDocumentOpen          call iced#repl#execute('document_open', <q-args>)
command! -nargs=? IcedDocumentPopupOpen     call iced#repl#execute('document_popup_open', <q-args>)
command!          IcedFormDocument          call iced#nrepl#document#current_form()
command! -nargs=? IcedUseCaseOpen           call iced#nrepl#document#usecase(<q-args>)
command!          IcedNextUseCase           call iced#nrepl#document#next_usecase()
command!          IcedPrevUseCase           call iced#nrepl#document#prev_usecase()
command!          IcedDocumentClose         call iced#nrepl#document#close()
command! -nargs=? IcedSourceShow            call iced#nrepl#source#show(<q-args>)
command! -nargs=? IcedSourcePopupShow       call iced#nrepl#source#popup_show(<q-args>)
command!          IcedCommandPalette        call iced#palette#show()
command! -nargs=? IcedSpecForm              call iced#nrepl#spec#form(<q-args>)
command! -nargs=? IcedSpecExample           call iced#nrepl#spec#example(<q-args>)
command! -nargs=? IcedClojureDocsOpen       call iced#clojuredocs#open(<q-args>)
command!          IcedClojureDocsRefresh    call iced#clojuredocs#refresh()

command!          IcedSlurp                 call iced#paredit#deep_slurp()
command!          IcedBarf                  call iced#paredit#barf()
command!          IcedFormat                call iced#format#current()
command!          IcedFormatAll             call iced#format#all()
command!          IcedCycleSrcAndTest       call iced#nrepl#navigate#cycle_src_and_test()
command! -nargs=? IcedGrep                  call iced#grep#exe(<q-args>)

command!          IcedBrowseRelatedNamespace call iced#nrepl#navigate#related_ns()
command!          IcedBrowseSpec             call iced#nrepl#spec#browse()
command!          IcedBrowseTestUnderCursor  call iced#nrepl#navigate#test()
command!          IcedBrowseReferences       call iced#nrepl#navigate#browse_references()
command!          IcedBrowseDependencies     call iced#nrepl#navigate#browse_dependencies()
command! -nargs=? IcedBrowseVarReferences    call iced#nrepl#navigate#browse_var_references(<q-args>)
command! -nargs=? IcedBrowseVarDependencies  call iced#nrepl#navigate#browse_var_dependencies(<q-args>)

command!          IcedClearNsCache          call iced#nrepl#ns#clear_cache()
command!          IcedClearCtrlpCache       call ctrlp#iced#cache#clear()

command!          IcedCleanNs               call iced#nrepl#refactor#clean_ns()
command!          IcedCleanAll              call iced#nrepl#refactor#clean_all()
command! -nargs=? IcedAddMissing            call iced#nrepl#refactor#add_missing_ns(<q-args>)
command! -nargs=? IcedAddNs                 call iced#nrepl#refactor#add_ns(<q-args>)
command!          IcedThreadFirst           call iced#nrepl#refactor#thread_first()
command!          IcedThreadLast            call iced#nrepl#refactor#thread_last()
command!          IcedExtractFunction       call iced#nrepl#refactor#extract_function()
command!          IcedAddArity              call iced#nrepl#refactor#add_arity()
command!          IcedMoveToLet             call iced#let#move_to_let()

command! -nargs=? -complete=custom,iced#nrepl#debug#complete_tapped
      \ IcedBrowseTapped                    call iced#nrepl#debug#browse_tapped(<q-args>)
command!          IcedClearTapped           call iced#nrepl#debug#clear_tapped()
command!
      \ IcedToggleWarnOnReflection          call iced#nrepl#debug#toggle_warn_on_reflection()

command! -nargs=? IcedToggleTraceVar        call iced#nrepl#trace#toggle_var(<q-args>)
command! -nargs=? IcedToggleTraceNs         call iced#nrepl#trace#toggle_ns(<q-args>)

command!          IcedInInitNs              call iced#nrepl#ns#in_init_ns()

command!          IcedJumpToNextSign        call iced#system#get('sign').jump_to_next()
command!          IcedJumpToPrevSign        call iced#system#get('sign').jump_to_prev()
command!          IcedJumpToNextError       call iced#system#get('sign').jump_to_next({'name': iced#nrepl#test#sign_name()})
command!          IcedJumpToPrevError       call iced#system#get('sign').jump_to_next({'name': iced#nrepl#test#sign_name()})
command!          IcedJumpToLet             call iced#let#jump_to_let()

command!          IcedStartSideloader        call iced#nrepl#sideloader#start()
command!          IcedToggleSideloaderLookup call iced#nrepl#sideloader#toggle_enablement_of_lookup()

"" }}}

"" Key mappings {{{
nnoremap <silent> <Plug>(iced_connect)                  :<C-u>IcedConnect<CR>
nnoremap <silent> <Plug>(iced_disconnect)               :<C-u>IcedDisconnect<CR>
nnoremap <silent> <Plug>(iced_reconnect)                :<C-u>IcedReconnect<CR>
nnoremap <silent> <Plug>(iced_interrupt)                :<C-u>IcedInterrupt<CR>
nnoremap <silent> <Plug>(iced_interrupt_all)            :<C-u>IcedInterruptAll<CR>
nnoremap <silent> <Plug>(iced_instant_connect)          :<C-u>IcedInstantConnect<CR>
nnoremap <silent> <Plug>(iced_jack_in)                  :<C-u>IcedJackIn<CR>

nnoremap <silent> <Plug>(iced_start_cljs_repl)          :<C-u>IcedStartCljsRepl<CR>
nnoremap <silent> <Plug>(iced_quit_cljs_repl)           :<C-u>IcedQuitCljsRepl<CR>

nnoremap <silent> <Plug>(iced_eval)                     :<C-u>set opfunc=iced#operation#eval<CR>g@
nnoremap <silent> <Plug>(iced_eval_and_print)           :<C-u>set opfunc=iced#operation#eval_and_print<CR>g@
nnoremap <silent> <Plug>(iced_eval_and_tap)             :<C-u>set opfunc=iced#operation#eval_and_tap<CR>g@
nnoremap <silent> <Plug>(iced_eval_and_replace)         :<C-u>set opfunc=iced#operation#eval_and_replace<CR>g@
nnoremap <silent> <Plug>(iced_eval_ns)                  :<C-u>IcedEvalNs<CR>
vnoremap <silent> <Plug>(iced_eval_visual)              :<C-u>IcedEvalVisual<CR>
nnoremap <silent> <Plug>(iced_macroexpand)              :<C-u>set opfunc=iced#operation#macroexpand<CR>g@
nnoremap <silent> <Plug>(iced_macroexpand_1)            :<C-u>set opfunc=iced#operation#macroexpand_1<CR>g@
nnoremap <silent> <Plug>(iced_require)                  :<C-u>IcedRequire<CR>
nnoremap <silent> <Plug>(iced_require_all)              :<C-u>IcedRequireAll<CR>
nnoremap <silent> <Plug>(iced_undef)                    :<C-u>IcedUndef<CR>
nnoremap <silent> <Plug>(iced_undef_all_in_ns)          :<C-u>IcedUndefAllInNs<CR>
nnoremap <silent> <Plug>(iced_eval_outer_top_list)      :<C-u>IcedEvalOuterTopList<CR>
nnoremap <silent> <Plug>(iced_eval_at_mark)             :<C-u>IcedEvalAtMark<CR>
nnoremap <silent> <Plug>(iced_print_last)               :<C-u>IcedPrintLast<CR>
nnoremap <silent> <Plug>(iced_macroexpand_outer_list)   :<C-u>IcedMacroExpandOuterList<CR>
nnoremap <silent> <Plug>(iced_macroexpand_1_outer_list) :<C-u>IcedMacroExpand1OuterList<CR>

nnoremap <silent> <Plug>(iced_test_ns)                  :<C-u>IcedTestNs<CR>
nnoremap <silent> <Plug>(iced_test_all)                 :<C-u>IcedTestAll<CR>
nnoremap <silent> <Plug>(iced_test_redo)                :<C-u>IcedTestRedo<CR>
nnoremap <silent> <Plug>(iced_test_under_cursor)        :<C-u>IcedTestUnderCursor<CR>
nnoremap <silent> <Plug>(iced_test_rerun_last)          :<C-u>IcedTestRerunLast<CR>
nnoremap <silent> <Plug>(iced_test_spec_check)          :<C-u>IcedTestSpecCheck<CR>
nnoremap <silent> <Plug>(iced_test_buffer_open)         :<C-u>IcedTestBufferOpen<CR>

nnoremap <silent> <Plug>(iced_stdout_buffer_open)       :<C-u>IcedStdoutBufferOpen<CR>
nnoremap <silent> <Plug>(iced_stdout_buffer_clear)      :<C-u>IcedStdoutBufferClear<CR>
nnoremap <silent> <Plug>(iced_stdout_buffer_close)      :<C-u>IcedStdoutBufferClose<CR>

nnoremap <silent> <Plug>(iced_def_jump)                 :<C-u>IcedDefJump<CR>

nnoremap <silent> <Plug>(iced_document_open)            :<C-u>IcedDocumentOpen<CR>
nnoremap <silent> <Plug>(iced_document_popup_open)      :<C-u>IcedDocumentPopupOpen<CR>
nnoremap <silent> <Plug>(iced_form_document)            :<C-u>IcedFormDocument<CR>
nnoremap <silent> <Plug>(iced_use_case_open)            :<C-u>IcedUseCaseOpen<CR>
nnoremap <silent> <Plug>(iced_next_use_case)            :<C-u>IcedNextUseCase<CR>
nnoremap <silent> <Plug>(iced_prev_use_case)            :<C-u>IcedPrevUseCase<CR>
nnoremap <silent> <Plug>(iced_document_close)           :<C-u>IcedDocumentClose<CR>
nnoremap <silent> <Plug>(iced_source_show)              :<C-u>IcedSourceShow<CR>
nnoremap <silent> <Plug>(iced_source_popup_show)        :<C-u>IcedSourcePopupShow<CR>
nnoremap <silent> <Plug>(iced_command_palette)          :<C-u>IcedCommandPalette<CR>
nnoremap <silent> <Plug>(iced_spec_form)                :<C-u>IcedSpecForm<CR>
nnoremap <silent> <Plug>(iced_spec_example)             :<C-u>IcedSpecExample<CR>
nnoremap <silent> <Plug>(iced_clojuredocs_open)         :<C-u>IcedClojureDocsOpen<CR>
nnoremap <silent> <Plug>(iced_clojuredocs_refresh)      :<C-u>IcedClojureDocsRefresh<CR>

nnoremap <silent> <Plug>(iced_slurp)                    :<C-u>IcedSlurp<CR>
nnoremap <silent> <Plug>(iced_barf)                     :<C-u>IcedBarf<CR>
nnoremap <silent> <Plug>(iced_format)                   :<C-u>IcedFormat<CR>
nnoremap <silent> <Plug>(iced_format_all)               :<C-u>IcedFormatAll<CR>
nnoremap <silent> <Plug>(iced_cycle_src_and_test)       :<C-u>IcedCycleSrcAndTest<CR>
nnoremap <silent> <Plug>(iced_grep)                     :<C-u>IcedGrep<CR>

nnoremap <silent> <Plug>(iced_browse_related_namespace) :<C-u>IcedBrowseRelatedNamespace<CR>
nnoremap <silent> <Plug>(iced_browse_spec)              :<C-u>IcedBrowseSpec<CR>
nnoremap <silent> <Plug>(iced_browse_test_under_cursor) :<C-u>IcedBrowseTestUnderCursor<CR>
nnoremap <silent> <Plug>(iced_browse_references)        :<C-u>IcedBrowseReferences<CR>
nnoremap <silent> <Plug>(iced_browse_dependencies)      :<C-u>IcedBrowseDependencies<CR>
nnoremap <silent> <Plug>(iced_browse_var_references)    :<C-u>IcedBrowseVarReferences<CR>
nnoremap <silent> <Plug>(iced_browse_var_dependencies)  :<C-u>IcedBrowseVarDependencies<CR>

nnoremap <silent> <Plug>(iced_clear_ns_cache)           :<C-u>IcedClearNsCache<CR>
nnoremap <silent> <Plug>(iced_clear_ctrlp_cache)        :<C-u>IcedClearCtrlpCache<CR>

nnoremap <silent> <Plug>(iced_clean_ns)                 :<C-u>IcedCleanNs<CR>
nnoremap <silent> <Plug>(iced_clean_all)                :<C-u>IcedCleanAll<CR>
nnoremap <silent> <Plug>(iced_add_missing)              :<C-u>IcedAddMissing<CR>
nnoremap <silent> <Plug>(iced_add_ns)                   :<C-u>IcedAddNs<CR>
nnoremap <silent> <Plug>(iced_thread_first)             :<C-u>IcedThreadFirst<CR>
nnoremap <silent> <Plug>(iced_thread_last)              :<C-u>IcedThreadLast<CR>
nnoremap <silent> <Plug>(iced_extract_function)         :<C-u>IcedExtractFunction<CR>
nnoremap <silent> <Plug>(iced_add_arity)                :<C-u>IcedAddArity<CR>
nnoremap <silent> <Plug>(iced_move_to_let)              :<C-u>IcedMoveToLet<CR>

nnoremap <silent> <Plug>(iced_browse_tapped)            :<C-u>IcedBrowseTapped<CR>
nnoremap <silent> <Plug>(iced_clear_tapped)             :<C-u>IcedClearTapped<CR>
nnoremap <silent>
      \ <Plug>(iced_toggle_warn_on_reflection)          :<C-u>IcedToggleWarnOnReflection<CR>

nnoremap <silent> <Plug>(iced_toggle_trace_ns)          :<C-u>IcedToggleTraceNs<CR>
nnoremap <silent> <Plug>(iced_toggle_trace_var)         :<C-u>IcedToggleTraceVar<CR>

nnoremap <silent> <Plug>(iced_in_init_ns)               :<C-u>IcedInInitNs<CR>

nnoremap <silent> <Plug>(iced_jump_to_next_sign)        :<C-u>IcedJumpToNextSign<CR>
nnoremap <silent> <Plug>(iced_jump_to_prev_sign)        :<C-u>IcedJumpToPrevSign<CR>
nnoremap <silent> <Plug>(iced_jump_to_let)              :<C-u>IcedJumpToLet<CR>

nnoremap <silent> <Plug>(iced_start_sideloader)         :<C-u>IcedStartSideloader<CR>
nnoremap <silent> <Plug>(iced_toggle_sideloader_lookup) :<C-u>IcedToggleSideloaderLookup<CR>

"" }}}

"" Auto commands {{{
aug vim_iced_initial_setting
  au!
  au FileType clojure setl omnifunc=iced#complete#omni
  au BufRead *.clj,*.cljs,*.cljc call iced#nrepl#auto#bufread()
  au BufNewFile *.clj,*.cljs,*.cljc call iced#nrepl#auto#newfile()
  au BufEnter *.clj,*.cljs,*.cljc call iced#nrepl#auto#bufenter()
  au VimLeave * call iced#nrepl#auto#leave()
aug END

if g:iced_enable_auto_document ==# 'normal'
      \ || g:iced_enable_auto_document ==# 'every'
  aug vim_iced_auto_document_normal
    au!
    au CursorHold *.clj,*.cljs,*.cljc call iced#nrepl#document#current_form()
  aug END
endif

if g:iced_enable_auto_document ==# 'insert'
      \ || g:iced_enable_auto_document ==# 'every'
  aug vim_iced_auto_document_insert
    au!
    au CursorHoldI *.clj,*.cljs,*.cljc call iced#nrepl#document#current_form()
  aug END
endif

" NOTE: Neovim does not have `moved` option for floating window.
"       So vim-iced must close floating window explicitly.
if has('nvim') && exists('*nvim_open_win')
  aug vim_iced_close_document_popup
    au!
    au CursorMoved *.clj,*.cljs,*.cljc call iced#component#popup#neovim#moved()
  aug END
endif
"" }}}

"" Default mappings {{{
function! s:default_key_mappings() abort
  if !hasmapto('<Plug>(iced_connect)')
    silent! nmap <buffer> <Leader>' <Plug>(iced_connect)
  endif

  "" Evaluating (<Leader>e)
  "" ------------------------------------------------------------------------
  if !hasmapto('<Plug>(iced_interrupt)')
    silent! nmap <buffer> <Leader>eq <Plug>(iced_interrupt)
  endif

  if !hasmapto('<Plug>(iced_interrupt_all)')
    silent! nmap <buffer> <Leader>eQ <Plug>(iced_interrupt_all)
  endif

  if !hasmapto('<Plug>(iced_jack_in)')
    silent! nmap <buffer> <Leader>" <Plug>(iced_jack_in)
  endif

  if !hasmapto('<Plug>(iced_eval)')
    silent! nmap <buffer> <Leader>ei <Plug>(iced_eval)<Plug>(sexp_inner_element)``
    silent! nmap <buffer> <Leader>ee <Plug>(iced_eval)<Plug>(sexp_outer_list)``
    silent! nmap <buffer> <Leader>et <Plug>(iced_eval_outer_top_list)
    silent! nmap <buffer> <Leader>ea <Plug>(iced_eval_at_mark)
  endif

  if !hasmapto('<Plug>(iced_eval_visual)')
    silent! vmap <buffer> <Leader>ee <Plug>(iced_eval_visual)
  endif

  if !hasmapto('<Plug>(iced_eval_ns)')
    silent! nmap <buffer> <Leader>en <Plug>(iced_eval_ns)
  endif

  if !hasmapto('<Plug>(iced_print_last)')
    silent! nmap <buffer> <Leader>ep <Plug>(iced_print_last)
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

  if !hasmapto('<Plug>(iced_undef_all_in_ns)')
    silent! nmap <buffer> <Leader>eU <Plug>(iced_undef_all_in_ns)
  endif

  if !hasmapto('<Plug>(iced_macroexpand_outer_list)')
    silent! nmap <buffer> <Leader>eM <Plug>(iced_macroexpand_outer_list)
  endif

  if !hasmapto('<Plug>(iced_macroexpand_1_outer_list)')
    silent! nmap <buffer> <Leader>em <Plug>(iced_macroexpand_1_outer_list)
  endif

  "" Testing (<Leader>t)
  "" ------------------------------------------------------------------------
  if !hasmapto('<Plug>(iced_test_under_cursor)')
    silent! nmap <buffer> <Leader>tt <Plug>(iced_test_under_cursor)
  endif

  if !hasmapto('<Plug>(iced_test_rerun_last)')
    silent! nmap <buffer> <Leader>tl <Plug>(iced_test_rerun_last)
  endif

  if !hasmapto('<Plug>(iced_test_spec_check)')
    silent! nmap <buffer> <Leader>ts <Plug>(iced_test_spec_check)
  endif

  if !hasmapto('<Plug>(iced_test_buffer_open)')
    silent! nmap <buffer> <Leader>to <Plug>(iced_test_buffer_open)
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

  "" Stdout buffer (<Leader>s)
  "" ------------------------------------------------------------------------
  if !hasmapto('<Plug>(iced_stdout_buffer_open)')
    silent! nmap <buffer> <Leader>ss <Plug>(iced_stdout_buffer_open)
  endif

  if !hasmapto('<Plug>(iced_stdout_buffer_clear)')
    silent! nmap <buffer> <Leader>sl <Plug>(iced_stdout_buffer_clear)
  endif

  if !hasmapto('<Plug>(iced_stdout_buffer_close)')
    silent! nmap <buffer> <Leader>sq <Plug>(iced_stdout_buffer_close)
  endif

  "" Refactoring (<Leader>r)
  "" ------------------------------------------------------------------------
  if !hasmapto('<Plug>(iced_clean_ns)')
    silent! nmap <buffer> <Leader>rcn <Plug>(iced_clean_ns)
  endif

  if !hasmapto('<Plug>(iced_clean_all)')
    silent! nmap <buffer> <Leader>rca <Plug>(iced_clean_all)
  endif

  if !hasmapto('<Plug>(iced_add_missing)')
    silent! nmap <buffer> <Leader>ram <Plug>(iced_add_missing)
  endif

  if !hasmapto('<Plug>(iced_add_ns)')
    silent! nmap <buffer> <Leader>ran <Plug>(iced_add_ns)
  endif

  if !hasmapto('<Plug>(iced_thread_first)')
    silent! nmap <buffer> <Leader>rtf <Plug>(iced_thread_first)
  endif

  if !hasmapto('<Plug>(iced_thread_last)')
    silent! nmap <buffer> <Leader>rtl <Plug>(iced_thread_last)
  endif

  if !hasmapto('<Plug>(iced_extract_function)')
    silent! nmap <buffer> <Leader>ref <Plug>(iced_extract_function)
  endif

  if !hasmapto('<Plug>(iced_add_arity)')
    silent! nmap <buffer> <Leader>raa <Plug>(iced_add_arity)
  endif

  if !hasmapto('<Plug>(iced_move_to_let)')
    silent! nmap <buffer> <Leader>rml <Plug>(iced_move_to_let)
  endif

  "" Help/Document (<Leader>h)
  "" ------------------------------------------------------------------------
  if !hasmapto('<Plug>(iced_document_popup_open)')
    silent! nmap <buffer> K <Plug>(iced_document_popup_open)
  endif

  if !hasmapto('<Plug>(iced_document_open)')
    silent! nmap <buffer> <Leader>hb <Plug>(iced_document_open)
  endif

  if !hasmapto('<Plug>(iced_use_case_open)')
    silent! nmap <buffer> <Leader>hu <Plug>(iced_use_case_open)
  endif

  if !hasmapto('<Plug>(iced_next_use_case)')
    silent! nmap <buffer> <Leader>hn <Plug>(iced_next_use_case)
  endif

  if !hasmapto('<Plug>(iced_prev_use_case)')
    silent! nmap <buffer> <Leader>hN <Plug>(iced_prev_use_case)
  endif

  if !hasmapto('<Plug>(iced_document_close)')
    silent! nmap <buffer> <Leader>hq <Plug>(iced_document_close)
  endif

  if !hasmapto('<Plug>(iced_source_show)')
    silent! nmap <buffer> <Leader>hS <Plug>(iced_source_show)
  endif

  if !hasmapto('<Plug>(iced_source_popup_show)')
    silent! nmap <buffer> <Leader>hs <Plug>(iced_source_popup_show)
  endif

  if !hasmapto('<Plug>(iced_clojuredocs_open)')
    silent! nmap <buffer> <Leader>hc <Plug>(iced_clojuredocs_open)
  endif

  if !hasmapto('<Plug>(iced_command_palette)')
    silent! nmap <buffer> <Leader>hh <Plug>(iced_command_palette)
  endif


  "" Browsing (<Leader>b)
  "" ------------------------------------------------------------------------
  if !hasmapto('<Plug>(iced_browse_related_namespace)')
    silent! nmap <buffer> <Leader>bn <Plug>(iced_browse_related_namespace)
  endif

  if !hasmapto('<Plug>(iced_browse_spec)')
    silent! nmap <buffer> <Leader>bs <Plug>(iced_browse_spec)
  endif

  if !hasmapto('<Plug>(iced_browse_test_under_cursor)')
    silent! nmap <buffer> <Leader>bt <Plug>(iced_browse_test_under_cursor)
  endif

  if !hasmapto('<Plug>(iced_browse_references)')
    silent! nmap <buffer> <Leader>br <Plug>(iced_browse_references)
  endif

  if !hasmapto('<Plug>(iced_browse_dependencies)')
    silent! nmap <buffer> <Leader>bd <Plug>(iced_browse_dependencies)
  endif

  if !hasmapto('<Plug>(iced_browse_var_references)')
    silent! nmap <buffer> <Leader>bvr <Plug>(iced_browse_var_references)
  endif

  if !hasmapto('<Plug>(iced_browse_var_dependencies)')
    silent! nmap <buffer> <Leader>bvd <Plug>(iced_browse_var_dependencies)
  endif

  "" Jumping cursor (<Leader>j)
  "" ------------------------------------------------------------------------
  if !hasmapto('<Plug>(iced_def_jump)')
    silent! nmap <buffer> <C-]> <Plug>(iced_def_jump)
  endif

  if !hasmapto('<Plug>(iced_jump_to_next_sign)')
    silent! nmap <buffer> <Leader>jn <Plug>(iced_jump_to_next_sign)
  endif

  if !hasmapto('<Plug>(iced_jump_to_prev_sign)')
    silent! nmap <buffer> <Leader>jN <Plug>(iced_jump_to_prev_sign)
  endif

  if !hasmapto('<Plug>(iced_jump_to_let)')
    silent! nmap <buffer> <Leader>jl <Plug>(iced_jump_to_let)
  endif

  "" Debugging (<Leader>d)
  "" ------------------------------------------------------------------------
  if !hasmapto('<Plug>(iced_browse_tapped)')
    silent! nmap <buffer> <Leader>dbt <Plug>(iced_browse_tapped)
  endif

  if !hasmapto('<Plug>(iced_clear_tapped)')
    silent! nmap <buffer> <Leader>dlt <Plug>(iced_clear_tapped)
  endif

  "" Misc
  "" ------------------------------------------------------------------------
  if !hasmapto('<Plug>(iced_format)')
    silent! nmap <buffer> == <Plug>(iced_format)
  endif

  if !hasmapto('<Plug>(iced_format_all)')
    silent! nmap <buffer> =G <Plug>(iced_format_all)
  endif

  if !hasmapto('<Plug>(iced_grep)')
    silent! nmap <buffer> <Leader>* <Plug>(iced_grep)
    silent! nmap <buffer> <Leader>/ :<C-u>IcedGrep<Space>
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
let s:default_signs = {
      \ 'error': '🔥',
      \ 'trace': '👁',
      \ 'errorhl': 'ErrorMsg',
      \ 'tracehl': 'Search',
      \ }

let g:iced_sign = get(g:, 'iced_sign', {})
let sign_setting = extend(copy(s:default_signs), g:iced_sign)

for key in ['error', 'trace']
  exe printf(':sign define %s text=%s texthl=%s',
        \ 'iced_'.key,
        \ sign_setting[key],
        \ sign_setting[key.'hl'])
endfor
"" }}}

let &cpoptions = s:save_cpo
unlet s:save_cpo

