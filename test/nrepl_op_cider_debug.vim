let s:suite = themis#suite('iced.nrepl.op.cider.debug')
let s:assert = themis#helper('assert')
let s:ch = themis#helper('iced_channel')

let s:test = {'last_message': ''}
function! s:test.relay(msg) abort
  let self.last_message = a:msg
  return {'status': ['done'], 'message': a:msg}
endfunction

function! s:setup() abort
  call iced#nrepl#set_session('clj', 'clj-session')
  call iced#nrepl#set_session('repl', 'repl-session')
  call iced#nrepl#change_current_session('clj')
  call s:ch.register_test_builder({'status_value': 'open', 'relay': {v -> s:test.relay(v)}})
endfunction

function! s:suite.init_test() abort
  call s:setup()

  let g:iced#debug#print_length = 10
  let g:iced#debug#print_level = 20

  call iced#nrepl#op#cider#debug#init()
  call s:assert.equals(s:test.last_message, {
        \ 'session': 'clj-session',
        \ 'print-length': 10,
        \ 'print-level': 20,
        \ 'op': 'init-debugger'})
endfunction

function! s:suite.input_test() abort
  call s:setup()
  call iced#nrepl#op#cider#debug#input('k', 'i')
  call s:assert.equals(s:test.last_message, {
        \ 'session': 'clj-session',
        \ 'key': 'k',
        \ 'input': 'i',
        \ 'op': 'debug-input'})
endfunction
