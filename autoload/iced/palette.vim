let s:save_cpo = &cpo
set cpo&vim

let s:default_palette = [
      \ 'Connect', 'Disconnect', 'Reconnect', 'Interrupt',
      \ 'StartCljsRepl figwheel', 'StartCljsRepl nashorn',
      \ 'QuitCljsRepl',
      \ 'EvalNs',
      \ 'Require', 'RequireAll',
      \ 'PrintLast',
      \ 'TestNs', 'TestAll', 'TestRedo', 'TestSpecCheck', 'TestRerunLast',
      \ 'TestBufferOpen',
      \ 'StdoutBufferOpen', 'StdoutBufferClear', 'StdoutBufferClose',
      \ 'DocumentClose',
      \ 'ToggleSrcAndTest',
      \ 'RelatedNamespace', 'BrowseSpec',
      \ 'CleanNs', 'AddNs',
      \ 'ExtractFunction', 'MoveToLet',
      \ 'ToggleTraceVar', 'ToggleTraceNs',
      \ 'InReplNs',
      \ 'LintCurrentFile', 'LintToggle',
      \ 'JumpToNextSign', 'JumpToPrevSign',
      \ 'GotoLet',
      \ ]

function! s:build_palette() abort
  let palette = {}
  for cmd in s:default_palette
    let palette[cmd] = ':Iced'.cmd
  endfor

  let user_dict = get(g:, 'iced#palette#palette', {})
  for cmd in keys(user_dict)
    let palette[cmd] = user_dict[cmd]
  endfor

  return palette
endfunction

let s:palette = s:build_palette()

function! s:run(candidate) abort
  let cmd = get(s:palette, a:candidate, '')
  if !empty(cmd)
    execute cmd
  endif
endfunction

function! iced#palette#show() abort
  call iced#selector({
        \ 'candidates': keys(s:palette),
        \ 'accept': {_, candidate -> s:run(candidate)},
        \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
