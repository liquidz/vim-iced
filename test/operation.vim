let s:suite  = themis#suite('iced.operation')
let s:assert = themis#helper('assert')
let s:holder = themis#helper('iced_holder')
let s:timer = themis#helper('iced_timer')
let s:buf = themis#helper('iced_buffer')
let s:ch = themis#helper('iced_channel')
let s:repl = themis#helper('iced_repl')

function! s:setup() abort
  nnoremap <Plug>(iced_eval) :<C-u>call iced#operation#setup_eval()<CR>g@
  nmap <Plug>(iced_eval_test) <Plug>(iced_eval)<Plug>(sexp_outer_list)``
endfunction

function! s:suite.eval_test() abort
  call s:setup()
  call s:holder.clear()
  call s:repl.mock()
  call s:buf.start_dummy([
        \ '(ns foo.core)',
        \ '(foo (|bar))'])
  call s:ch.mock({'status_value': 'open', 'relay': {msg -> s:holder.relay(msg)}})

  let @x = ''
  execute "normal \<Plug>(iced_eval_test)"
  sleep 100ms

  let last_arg = s:holder.get_args()[-1]
  call s:assert.equals(last_arg['code'], '(bar)')
  call s:assert.equals(@x, '')

  call s:buf.stop_dummy()
endfunction

function! s:suite.eval_and_yank_test() abort
  call s:setup()
  call s:holder.clear()
  call s:repl.mock()
  call s:buf.start_dummy([
        \ '(ns foo.core)',
        \ '(foo (|bar))'])
  call s:ch.mock({'status_value': 'open', 'relay': {msg -> s:holder.relay(msg)}})

  let @x = ''
  execute "normal \"x\<Plug>(iced_eval_test)"
  sleep 100ms

  let last_arg = s:holder.get_args()[-1]
  call s:assert.equals(last_arg['code'], '(bar)')
  call s:assert.equals(@x, ':dummy/value')

  call s:buf.stop_dummy()
endfunction
