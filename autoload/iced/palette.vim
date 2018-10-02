let s:save_cpo = &cpo
set cpo&vim

let s:default_palette = [
      \ 'Connect',
      \ 'Disconnect',
      \ 'Reconnect',
      \ 'Interrupt',
      \ 'PrintLast',
      \ 'RequireAll',
      \ 'StartCljsRepl figwheel',
      \ 'StartCljsRepl nashorn',
      \ 'QuitCljsRepl',
      \ 'TestNs',
      \ 'TestAll',
      \ 'TestRedo',
      \ 'ToggleSrcAndTest',
      \ 'BrowseNamespace',
      \ 'BrowseFunction',
      \ 'BrowseSpec',
      \ 'CleanNs',
      \ 'AddNs',
      \ 'ToggleTraceVar',
      \ 'ToggleTraceNs',
      \ 'InReplNs',
      \ 'LintCurrentFile',
      \ 'LintToggle',
      \ ]

let g:iced#palette#palette = get(g:, 'iced#palette#palette', s:default_palette)

function! s:run(candidate) abort
  execute printf(':Iced%s', a:candidate)
endfunction

function! iced#palette#show() abort
  call ctrlp#iced#start({
        \ 'candidates': g:iced#palette#palette,
        \ 'accept': {_, candidate -> s:run(candidate)},
        \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
