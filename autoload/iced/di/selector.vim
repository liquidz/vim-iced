let s:save_cpo = &cpo
set cpo&vim

let s:selector = {}

function! s:selector.select(config) abort
  if globpath(&rtp, 'plugin/ctrlp.vim') !=# ''
    return ctrlp#iced#start(a:config)
  elseif globpath(&rtp, 'plugin/fzf.vim') !=# ''
    return fzf#iced#start(a:config)
  else
    return iced#message#error('no_selector')
  end
endfunction

function! iced#di#selector#build() abort
  return s:selector
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
