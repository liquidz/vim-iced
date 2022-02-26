let s:save_cpo = &cpoptions
set cpoptions&vim

let s:selector = {
      \ 'built_in': {
      \   'ctrlp': {'runtimepath':  'plugin/ctrlp.vim',
      \             'run': {config -> ctrlp#iced#start(config)}},
      \   'fzf': {'runtimepath': 'plugin/fzf.vim',
      \           'run': {config -> fzf#iced#start(config)}},
      \   'clap': {'runtimepath': 'plugin/clap.vim',
      \            'run': {config -> clap#provider#iced#start(config)}},
      \ }}

let g:iced#selector#external = get(g:, 'iced#selector#external', {})
let g:iced#selector#search_order = get(g:, 'iced#selector#search_order', ['ctrlp', 'fzf', 'clap'])

function! s:selector.selectors() abort
  return extend(copy(self.built_in), g:iced#selector#external)
endfunction

function! s:selector.select(config) abort
  let selectors = self.selectors()
  for target_name in g:iced#selector#search_order
    if ! has_key(selectors, target_name)
      call iced#message#error('unknown', target_name)
      continue
    endif

    if globpath(&runtimepath, selectors[target_name]['runtimepath']) !=# ''
      return selectors[target_name]['run'](a:config)
    endif
  endfor
  return iced#message#error('no_selector')
endfunction

function! iced#component#selector#start(_) abort
  call iced#util#debug('start', 'selector')
  return s:selector
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
