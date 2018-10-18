let s:save_cpo = &cpo
set cpo&vim

let s:default_mode = 'e'
let s:mode_dict = {
      \ 'ctrl-t': 't',
      \ 'crtl-v': 'v',
      \ }

function! s:sink(result, callback) abort
  if len(a:result) < 2 | return | endif
  let mode = get(s:mode_dict, a:result[0], s:default_mode)
  let text = iced#compat#trim(a:result[1])
  call a:callback(mode, text)
endfunction

function! fzf#iced#start(config) abort
  call fzf#run(fzf#wrap('iced', {
        \ 'source': a:config['candidates'],
        \ 'options': '--expect=ctrl-t,ctrl-v',
        \ 'sink*': {v -> s:sink(v, a:config['accept'])},
        \ }))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
