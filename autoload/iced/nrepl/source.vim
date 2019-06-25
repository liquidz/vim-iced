let s:save_cpo = &cpoptions
set cpoptions&vim

function! s:extract_source(resp) abort
  let path = get(a:resp, 'file', '')
  if empty(path) | return '' | endif

  let code = ''
  let reg_save = @@
  try
    call iced#buffer#temporary#begin()
    call iced#di#get('ex_cmd').silent_exe(
          \ printf(':read %s', iced#util#normalize_path(path)))
    call cursor(a:resp['line']+1, get(a:resp, 'column', 0))
    silent normal! vaby
    let code = @@
  finally
    let @@ = reg_save
    call iced#buffer#temporary#end()
  endtry

  return code
endfunction

function! s:fetch_source(symbol) abort
  return iced#promise#call('iced#nrepl#var#get', [a:symbol])
        \.then(funcref('s:extract_source'))
endfunction

function! iced#nrepl#source#show(symbol) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let symbol = empty(a:symbol) ? expand('<cword>') : a:symbol
  call s:fetch_source(symbol)
       \.then({code -> empty(code)
       \       ? iced#message#error('not_found')
       \       : iced#buffer#document#open(code, 'clojure')})
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
