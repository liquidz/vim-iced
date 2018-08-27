let s:save_cpo = &cpo
set cpo&vim

let s:debug_key = v:none

let s:commands = {
    \ 'c': ':IcedDebugContinue',
    \ 'l': ':IcedDebugLocals',
    \ 'n': ':IcedDebugNext',
    \ 'q': ':IcedDebugQuit',
    \ }

" c: continue
" e: eval
" h: here
" i: in
" j: inject
" l: locals
" n: next
" o: out
" p: inspect
" q: quit
" s: stacktrace
" t: trace
function! iced#nrepl#debug#start(resp) abort
  let s:debug_key = a:resp['key']
  call iced#buffer#stdout#append(" \n;; Debugging")
  call iced#buffer#stdout#append(a:resp['code'])
  call iced#buffer#stdout#append(";; --")

  let locals = a:resp['locals']
  echom printf('%s', locals)
  let ks = ['value'] + map(copy(locals), {_, v -> v[0]})
  echom printf('%s', ks)
  let max_key_len = max(map(ks, {_, v -> len(v)}))
  echom printf('%d', max_key_len)
  echom printf('%s', ([['value', a:resp['debug-value']]] + locals))
  for kv in ([['value', a:resp['debug-value']]] + locals)
    let [k, v] = kv
    call iced#buffer#stdout#append(printf('%' . max_key_len . 's: %s', k, v))
  endfor

  let input_type = a:resp['input-type']
  for k in keys(input_type)
    if !has_key(s:commands, k) | continue | endif
    call iced#buffer#stdout#append(printf(';; %s => %s', s:commands[k], input_type[k]))
  endfor
endfunction

function! iced#nrepl#debug#quit() abort
  if !empty(s:debug_key)
    let s:debug_key = v:none
    call iced#buffer#stdout#append(';; Quit')
  endif
endfunction

function! iced#nrepl#debug#input(in) abort
  call iced#nrepl#cider#debug#input(s:debug_key, a:in)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
