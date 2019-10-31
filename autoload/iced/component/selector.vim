let s:save_cpo = &cpoptions
set cpoptions&vim

let s:selector = {}

function! s:selector.select(config) abort
  if globpath(&runtimepath, 'plugin/ctrlp.vim') !=# ''
    return ctrlp#iced#start(a:config)
  elseif globpath(&runtimepath, 'plugin/fzf.vim') !=# ''
    return fzf#iced#start(a:config)
  elseif globpath(&runtimepath, 'plugin/clap.vim') !=# ''
    return clap#provider#iced#start(a:config)
  else
    return iced#message#error('no_selector')
  end
endfunction

function! iced#component#selector#new(_) abort
  call iced#util#debug('start', 'selector')
  return s:selector
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
