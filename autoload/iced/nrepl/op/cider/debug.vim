let s:save_cpo = &cpo
set cpo&vim

let g:iced#debug#print_length = get(g:, 'iced#debug#print_length', 10)
let g:iced#debug#print_level = get(g:, 'iced#debug#print_level', 10)

function! iced#nrepl#op#cider#debug#init() abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  call iced#nrepl#send({
      \ 'op': 'init-debugger',
      \ 'session': iced#nrepl#current_session(),
      \ 'print-length': g:iced#debug#print_length,
      \ 'print-level': g:iced#debug#print_level,
      \ })
endfunction

function! iced#nrepl#op#cider#debug#input(key, in) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#send({
      \ 'op': 'debug-input',
      \ 'session': iced#nrepl#current_session(),
      \ 'key': a:key,
      \ 'input': a:in,
      \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
