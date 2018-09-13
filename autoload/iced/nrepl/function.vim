let s:save_cpo = &cpo
set cpo&vim

let s:cache_name = 'functions'

function! s:open(mode, resp) abort
  if !has_key(a:resp, 'file') || empty(a:resp['file'])
    return iced#message#error('not_found')
  endif

  let path = substitute(a:resp['file'], '^file:', '', '')
  if !filereadable(path)
    return iced#message#error('not_found')
  endif

  let cmd = ':edit'
  if a:mode ==# 'v'
    let cmd = ':split'
  elseif a:mode ==# 't'
    let cmd = ':tabedit'
  endif
  exe printf('%s %s', cmd, path)

  call cursor(a:resp['line'], a:resp['column'])
  normal! zz
endfunction

function! s:resolve(mode, func_name) abort
  call iced#nrepl#cider#info(a:func_name, {resp -> s:open(a:mode, resp)})
endfunction

function! s:select(functions) abort
  if empty(a:functions) | return iced#message#error('not_found') | endif
  call ctrlp#iced#cache#write(s:cache_name, a:functions)
  call ctrlp#iced#start({'candidates': a:functions, 'accept': funcref('s:resolve')})
endfunction

function! iced#nrepl#function#list() abort
  if ctrlp#iced#cache#exists(s:cache_name)
    let lines = ctrlp#iced#cache#read(s:cache_name)
    call ctrlp#iced#start({'candidates': lines, 'accept': funcref('s:resolve')})
  else
    call iced#message#info('fetching')
    call iced#nrepl#iced#project_functions(funcref('s:select'))
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
