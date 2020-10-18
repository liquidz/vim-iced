let s:save_cpo = &cpo
set cpo&vim

" ns-list {{{
function! iced#nrepl#op#cider#sync#ns_list() abort
  if !iced#nrepl#is_connected()
    call iced#message#error('not_connected')
    return ''
  endif

  return iced#nrepl#sync#send({
      \ 'op': 'ns-list',
      \ 'session': iced#nrepl#current_session(),
      \ })
endfunction " }}}

" ns-path {{{
function! iced#nrepl#op#cider#sync#ns_path(ns) abort
  if !iced#nrepl#is_connected()
    call iced#message#error('not_connected')
    return ''
  endif

  return iced#nrepl#sync#send({
      \ 'op': 'ns-path',
      \ 'session': iced#nrepl#current_session(),
      \ 'ns': a:ns,
      \ })
endfunction " }}}

" classpath {{{
function! iced#nrepl#op#cider#sync#classpath() abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  return iced#nrepl#sync#send({
      \ 'op': 'classpath',
      \ 'session': iced#nrepl#current_session(),
      \ })
endfunction " }}}

call iced#nrepl#register_handler('classpath', function('iced#nrepl#path_translation_handler', [['classpath']]))

let &cpo = s:save_cpo
unlet s:save_cpo
" vim:fdm=marker:fdl=0
