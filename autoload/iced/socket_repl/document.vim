let s:save_cpo = &cpoptions
set cpoptions&vim

let s:popup_winid = -1

function! s:extract_document(resp) abort
  let out = get(a:resp, 'out', '')
  if empty(out) | return | endif

  " Drop last (prompt) line
  let docs = split(out, '\r\?\n')[0:-2]

  if docs == ['nil']
    call iced#message#error('not_found')
    return []
  endif

  return docs
endfunction

function! s:fetch_document(symbol, callback) abort
  let symbol = empty(a:symbol)
        \ ? iced#nrepl#var#cword()
        \ : a:symbol
  let code = join([
        \ '(when-let [m (some-> ''%s resolve meta)]',
        \ '  (clojure.string/join "\n" [(str "*" (:name m) "*")',
        \ '                             (:arglists m)',
        \ '                             (:doc m)]))',
        \ ])
  let code = printf(code, symbol)
  call iced#socket_repl#eval(code, {'callback': {resp -> a:callback(s:extract_document(resp))}})
endfunction

function! s:show_in_buffer(docs) abort
  if empty(a:docs) | return | endif
  call iced#buffer#document#open(join(a:docs, "\n"), 'help')
endfunction

function! s:show_on_popup(docs) abort
  if empty(a:docs) | return | endif
  let popup = iced#system#get('popup')
  if s:popup_winid != -1 | call popup.close(s:popup_winid) | endif
  let s:popup_winid = popup.open(a:docs, {
        \ 'line': 'near-cursor',
        \ 'col': col('.'),
        \ 'filetype': 'help',
        \ 'border': [],
        \ 'borderhighlight': ['Comment'],
        \ 'auto_close': v:false,
        \ 'moved': [0, &columns],
        \ })
endfunction

function! iced#socket_repl#document#open(symbol) abort
  return iced#promise#call(funcref('s:fetch_document'), [a:symbol])
        \.then(funcref('s:show_in_buffer'))
endfunction

function! iced#socket_repl#document#popup_open(symbol) abort
  if !iced#system#get('popup').is_supported()
    return iced#socket_repl#document#open(a:symbol)
  endif

  return iced#promise#call(funcref('s:fetch_document'), [a:symbol])
        \.then(funcref('s:show_on_popup'))
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
