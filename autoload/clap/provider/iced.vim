let s:save_cpo = &cpoptions
set cpoptions&vim

let s:config = {}
let s:default_mode = 'e'
let g:iced#clap#options = get(g:, 'iced#clap#options', [])

function! s:source() abort
  return copy(get(s:config, 'candidates', []))
endfunction

function! s:accept(value) abort
  let Callback = get(s:config, 'accept', '')
  if type(Callback) == v:t_func
    call Callback(s:default_mode, a:value)
  endif
endfunction

let g:clap#provider#iced# = {
      \ 'source': funcref('s:source'),
      \ 'sink': funcref('s:accept'),
      \ }

function! clap#provider#iced#start(config) abort
  let s:config = copy(a:config)
  let args = [v:false, 'iced']

  call extend(args, g:iced#clap#options)
  call call(function('clap#'), args)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
