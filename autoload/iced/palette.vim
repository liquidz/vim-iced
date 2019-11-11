let s:save_cpo = &cpoptions
set cpoptions&vim

let s:default_palette = [
      \ 'Connect', 'Disconnect', 'Reconnect', 'Interrupt', 'InterruptAll',
      \ 'InstantConnect', 'JackIn',
      \ 'StartCljsRepl figwheel-sidecar', 'StartCljsRepl graaljs', 'StartCljsRepl nashorn',
      \ 'QuitCljsRepl', 'CycleSession',
      \ 'EvalNs',
      \ 'Require', 'RequireAll',
      \ 'PrintLast',
      \ 'TestNs', 'TestAll', 'TestRedo', 'TestSpecCheck', 'TestRerunLast',
      \ 'TestBufferOpen',
      \ 'StdoutBufferOpen', 'StdoutBufferClear', 'StdoutBufferClose',
      \ 'DocumentClose', 'ClojureDocsRefresh',
      \ 'FormatAll',
      \ 'CycleSrcAndTest', 'Grep',
      \ 'BrowseRelatedNamespace', 'BrowseSpec', 'BrowseTestUnderCursor',
      \ 'BrowseReferences', 'BrowseDependencies',
      \ 'BrowseVarReferences', 'BrowseVarDependencies',
      \ 'CleanNs', 'CleanAll', 'AddNs',
      \ 'ExtractFunction', 'AddArity', 'MoveToLet',
      \ 'BrowseTapped', 'ClearTapped',
      \ 'ToggleWarnOnReflection', 'ToggleTraceVar', 'ToggleTraceNs',
      \ 'InInitNs',
      \ 'JumpToNextSign', 'JumpToPrevSign',
      \ 'JumpToLet',
      \ ]

function! s:build_palette() abort
  let palette = {}
  for cmd in s:default_palette
    let palette[cmd] = ':Iced'.cmd
  endfor

  let user_dict = get(g:, 'iced#palette', {})
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

let &cpoptions = s:save_cpo
unlet s:save_cpo
