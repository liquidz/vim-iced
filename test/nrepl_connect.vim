let s:suite = themis#suite('iced.nrepl.connect')
let s:assert = themis#helper('assert')
let s:ch = themis#helper('iced_channel')
let s:timer = themis#helper('iced_timer')
let s:job = themis#helper('iced_job')

let s:default_dir = printf('%s/resources/connect/default', expand('<sfile>:h'))
let s:shadow_cljs_dir = printf('%s/resources/connect/shadow_cljs', expand('<sfile>:h'))

function! s:auto_relay(msg) abort
  if a:msg['op'] ==# 'clone'
    return {'status': ['done'], 'new-session': 'fixme'}
  endif
  return {'status': ['done']}
endfunction

function! s:setup() abort
  let g:iced#nrepl#connect#iced_command = 'ls'
  let g:iced#nrepl#connect#clj_command = 'ls'
  let g:iced#nrepl#connect#jack_in_command = 'ls -ltr'
endfunction

function! s:suite.auto_test() abort
  call s:ch.register_test_builder({
    \ 'status_value': ['fail', 'fail', 'open'],
    \ 'relay': funcref('s:auto_relay'),
    \ })
  let cwd = getcwd()

  try
    set hidden
    silent execute printf(':lcd %s', s:default_dir)
    call s:assert.equals(iced#nrepl#connect#auto(), v:true)

    let opened_args = iced#di#get('channel').get_opened_args()
    call s:assert.equals(opened_args['address'], '127.0.0.1:123456')
  finally
    silent execute printf(':lcd %s', cwd)
  endtry
endfunction

function! s:suite.auto_with_shadow_cljs_test() abort
  call s:ch.register_test_builder({
    \ 'status_value': ['fail', 'fail', 'open'],
    \ 'relay': funcref('s:auto_relay'),
    \ })
  let cwd = getcwd()

  try
    set hidden
    silent execute printf(':lcd %s', s:shadow_cljs_dir)
    call s:assert.equals(iced#nrepl#connect#auto(), v:true)

    let opened_args = iced#di#get('channel').get_opened_args()
    call s:assert.equals(opened_args['address'], '127.0.0.1:234567')
  finally
    silent execute printf(':lcd %s', cwd)
  endtry
endfunction

function! s:suite.jack_in_test() abort
  call s:setup()
  call s:timer.register_test_builder()
  call s:job.register_test_builder({'outs': ['nREPL server started']})
  call s:ch.register_test_builder({
      \ 'status_value': ['fail', 'fail',
      \                  'fail', 'fail',  'open'],
      \ 'relay': funcref('s:auto_relay'),
      \ })
  let cwd = getcwd()

  try
    set hidden
    silent execute printf(':lcd %s', s:default_dir)

    call iced#nrepl#connect#jack_in()

    let opened_args = iced#di#get('channel').get_opened_args()
    call s:assert.equals(opened_args['address'], '127.0.0.1:123456')
    call s:assert.equals(s:job.get_last_command(), 'ls -ltr')
  finally
    silent execute printf(':lcd %s', cwd)
    call iced#nrepl#connect#reset()
  endtry
endfunction

function! s:suite.instant_test() abort
  call s:setup()
  call s:timer.register_test_builder()
  call s:job.register_test_builder({'outs': ['nREPL server started']})
  call s:ch.register_test_builder({
    \ 'status_value': ['fail', 'fail',
    \                  'fail', 'fail',  'open'],
    \ 'relay': funcref('s:auto_relay'),
    \ })
  let cwd = getcwd()

  try
    set hidden
    silent execute printf(':lcd %s', s:default_dir)

    call iced#nrepl#connect#instant()

    let opened_args = iced#di#get('channel').get_opened_args()
    call s:assert.equals(opened_args['address'], '127.0.0.1:123456')
    call s:assert.equals(s:job.get_last_command(), 'ls repl --instant')
  finally
    silent execute printf(':lcd %s', cwd)
    call iced#nrepl#connect#reset()
  endtry
endfunction
