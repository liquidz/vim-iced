if (exists('g:loaded_ctrlp_iced') && g:loaded_ctrlp_iced) || &cp
  finish
endif
let g:loaded_ctrlp_iced = 1

let s:config = {
    \ 'candidates': [],
    \ 'accept': '',
    \ }

if exists('g:loaded_ctrlp')
  call add(g:ctrlp_ext_vars, {
      \ 'init':      'ctrlp#iced#init()',
      \ 'accept':    'ctrlp#iced#accept',
      \ 'lname':     'vim-iced',
      \ 'sname':     'iced',
      \ 'type':      'tabs',
      \ 'sort':      0,
      \ 'specinput': 0,
      \ })
  let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
endif

function! ctrlp#iced#init() abort
  if has_key(s:config, 'init')
    let Init = s:config['init']
    return Init()
  else
    return get(s:config, 'candidates', [])
  endif
endfunction

function! ctrlp#iced#accept(mode, line) abort
  call ctrlp#exit()
  let config = copy(s:config)
  let s:config = {}

  let Callback = get(config, 'accept', '')
  if iced#util#is_function(Callback)
    call Callback(a:mode, a:line)
  endif
endfunction

function! ctrlp#iced#id() abort
  return s:id
endfunction

function! ctrlp#iced#start(config) abort
  if !exists('g:loaded_ctrlp')
    return iced#message#error('no_ctrlp')
  endif

  let s:config = copy(a:config)
  call ctrlp#init(ctrlp#iced#id())
endfunction

