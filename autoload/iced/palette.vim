let s:save_cpo = &cpoptions
set cpoptions&vim

let s:default_palette = [
      \ 'Connect', 'Disconnect', 'Reconnect', 'Interrupt', 'InterruptAll',
      \ 'InstantConnect', 'InstantConnect babashka', 'InstantConnect nbb', 'JackIn',
      \ 'StartCljsRepl {{env}}',
      \ 'QuitCljsRepl', 'CycleSession',
      \ 'EvalNs', 'Undef', 'UndefAllInNs', 'UnaliasNs',
      \ 'Require', 'RequireAll', 'Refresh', 'RefreshAll', 'RefreshClear',
      \ 'PrintLast',
      \ 'TestNs', 'TestAll', 'TestRedo', 'TestSpecCheck', 'TestRerunLast',
      \ 'TestBufferOpen',
      \ 'StdoutBufferOpen', 'StdoutBufferClear', 'StdoutBufferClose', 'StdoutBufferToggle',
      \ 'JavaDocument', 'DocumentClose', 'ClojureDocsRefresh',
      \ 'FormatAll',
      \ 'UseCaseOpen', 'NextUseCase', 'PrevUseCase',
      \ 'CycleSrcAndTest', 'Grep',
      \ 'BrowseRelatedNamespace', 'BrowseSpec', 'BrowseTestUnderCursor',
      \ 'BrowseReferences', 'BrowseDependencies',
      \ 'CleanNs', 'CleanAll', 'AddNs', 'AddMissing',
      \ 'ExtractFunction', 'AddArity', 'MoveToLet',
      \ 'RenameSymbol', 'YankNsName',
      \ 'BrowseTapped', 'DeleteTapped', 'ClearTapped',
      \ 'ToggleWarnOnReflection', 'ToggleTraceVar', 'ToggleTraceNs',
      \ 'InInitNs',
      \ 'JumpToNextSign', 'JumpToPrevSign',
      \ 'JumpToLet',
      \ 'StartSideloader', 'StopSideloader',
      \ 'ClearNsCache',
      \ 'UpdateTool {{tool-name}}>',
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
    let arr = split(cmd, ' ')
    if len(arr) == 1 || stridx(arr[-1], '{{') == -1
      call histadd('cmd', strpart(cmd, 1))
      call iced#system#get('future').do({-> iced#system#get('ex_cmd').exe(cmd)})
    else
      " Remove last element, but remain last space
      let arr[-1] = ''
      let cmd = join(arr, ' ')
      call feedkeys(cmd, 'n')
    endif
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
