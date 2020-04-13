let s:suite  = themis#suite('iced.complete')
let s:assert = themis#helper('assert')
let s:scope  = themis#helper('scope')
let s:ch     = themis#helper('iced_channel')
let s:buf    = themis#helper('iced_buffer')
let s:repl   = themis#helper('iced_repl')
let s:funcs  = s:scope.funcs('autoload/iced/complete.vim')

function! s:suite.omni_findstart_test() abort
  call s:buf.start_dummy([
        \ '(defn foo [x]',
        \ '  (let [y 1]',
        \ '    (+ | y)))',
        \ ])
  call s:assert.equals(iced#complete#omni(v:true, 'base'), 7)
  call s:buf.stop_dummy()
endfunction

function! s:complete_relay(msg) abort
  let op = a:msg['op']
  if op ==# 'complete'
    return {'status': ['done'], 'completions': [
          \ {'candidate': 'foo', 'arglists': ['bar'], 'doc': 'baz', 'type': 'function'},
          \ {'candidate': 'hello', 'type': 'namespace'},
          \ ]}
  elseif op ==# 'describe'
    return {'status': ['done'], 'ops': {'complete': {}}}
  endif
  return {'status': ['done']}
endfunction

function! s:suite.omni_test() abort
  let g:iced_enable_enhanced_cljs_completion = v:false
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:complete_relay')})
  call s:repl.mock()
  call s:buf.start_dummy([])

  call s:assert.equals(
        \ iced#complete#omni(v:false, 'base'),
        \ [
        \   {'word': 'foo', 'menu': 'bar', 'info': 'baz', 'kind': 'f', 'icase': 1},
        \   {'word': 'hello', 'menu': '', 'info': '', 'kind': 'n', 'icase': 1},
        \ ])

  call s:buf.stop_dummy()
endfunction

function! s:suite.omni_without_connection_test() abort
  call s:repl.mock('non_existing_component')
  call s:assert.equals(iced#complete#omni(v:false, 'base'), [])
endfunction
