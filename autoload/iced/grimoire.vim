let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:Http = s:V.import('Web.HTTP')

let s:grimoire_url = 'https://conj.io'

function! s:build_url(platform, ns_name, symbol) abort
  " ex. https://conj.io/search/v1/clj/clojure.core/defrecord/
  return printf('%s/search/v1/%s/%s/%s/',
      \ s:grimoire_url, a:platform, a:ns_name, a:symbol)
endfunction

function! s:search(resp) abort
  if has_key(a:resp, 'ns')
    " NOTE: $PLATFORM must be 'clj', 'cljs', or 'cljclr'
    let platform = iced#nrepl#current_session_key()
    let ns_name = a:resp['ns']
    let symbol = a:resp['name']
    let url = s:build_url(platform, ns_name, symbol)

    echom printf('Connecting to %s ...', s:grimoire_url)

    let resp = s:Http.get(url, {}, {'Content-Type': 'text/plain'})
    if resp['status'] == 200
      call iced#preview#view(resp['content'], 'markdown')
    elseif resp['status'] == 404
      echom printf('Not found.')
    else
      echom printf('Invalid status: %d', resp['status'])
    endif
  else
    echom printf('Invalid response from Grimoire.')
  endif
endfunction

function! iced#grimoire#open(symbol) abort
  let symbol = empty(a:symbol) ? expand('<cword>') : a:symbol
  call iced#nrepl#cider#info(symbol, funcref('s:search'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
