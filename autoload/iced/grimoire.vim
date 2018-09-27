let s:save_cpo = &cpo
set cpo&vim

function! s:grimoire(resp) abort
  if !has_key(a:resp, 'content') || empty(a:resp['content'])
    return iced#message#error('not_found')
  endif

  call iced#buffer#document#open(a:resp['content'])
endfunction

function! s:search(resp) abort
  if has_key(a:resp, 'ns')
    " NOTE: $PLATFORM must be 'clj', 'cljs', or 'cljclr'
    let platform = iced#nrepl#current_session_key()
    let ns_name = a:resp['ns']
    let symbol = a:resp['name']

    echom printf('Connecting to grimoire ...')
    call iced#nrepl#op#iced#grimoire(platform, ns_name, symbol, funcref('s:grimoire'))
  else
    echom printf('Invalid response from Grimoire.')
  endif
endfunction

function! iced#grimoire#open(symbol) abort
  let symbol = empty(a:symbol) ? expand('<cword>') : a:symbol
  call iced#nrepl#op#cider#info(symbol, funcref('s:search'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
