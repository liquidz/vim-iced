if (exists('g:loaded_ctrlp_iced') && g:loaded_ctrlp_iced) || &cp
  finish
endif
let g:loaded_ctrlp_iced = 1

let s:config = {
    \ 'candidates': [],
    \ 'accept': v:none,
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

function! s:link_highlight(from, to) abort
  if !hlexists(a:from)
    exe 'highlight link' a:from a:to
  endif
endfunction

function! s:set_syntax() abort
  call s:link_highlight('IcedCtrlpTitle', 'Identifier')
  call s:link_highlight('IcedCtrlpOptions', 'Comment')
  syntax match IcedCtrlpTitle '^> [^\t]\+'
  syntax match IcedCtrlpOptions '\zs\t.*\ze$'
endfunction

function! ctrlp#iced#init() abort
  call s:set_syntax()
  return get(s:config, 'candidates', [])
endfunction

function! ctrlp#iced#accept(mode, line) abort
  call ctrlp#exit()
  let config = copy(s:config)
  let s:config = {}

  let Callback = get(config, 'accept', v:none)
  if iced#util#is_function(Callback)
    call Callback(a:mode, a:line)
  endif
endfunction

function! ctrlp#iced#id() abort
  return s:id
endfunction

function! ctrlp#iced#start(config) abort
  if !exists('g:loaded_ctrlp')
    echom iced#message#get('no_ctrlp')
    return
  endif

  let s:config = copy(a:config)
  call ctrlp#init(ctrlp#iced#id())
endfunction

