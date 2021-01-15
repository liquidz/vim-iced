let s:suite = themis#suite('iced.nrepl.connect')
let s:assert = themis#helper('assert')
let s:ch = themis#helper('iced_channel')
let s:timer = themis#helper('iced_timer')
let s:job = themis#helper('iced_job')

let s:project_dir = expand('<sfile>:h:h')
let s:project_deps_edn = printf('%s/deps.edn', s:project_dir)
let s:default_dir = printf('%s/resources/connect/default', expand('<sfile>:h'))
let s:default_tmpfile = printf('%s/%s', s:default_dir, 'tmp.clj')
let s:shadow_cljs_dir = printf('%s/resources/connect/shadow_cljs', expand('<sfile>:h'))
let s:shadow_cljs_tmpfile = printf('%s/%s', s:shadow_cljs_dir, 'tmp.clj')

function! s:auto_relay(msg) abort
  if a:msg['op'] ==# 'clone'
    return {'status': ['done'], 'new-session': 'fixme'}
  elseif a:msg['op'] ==# 'eval'
    return {'status': ['done'], 'value': 'user'}
  endif
  return {'status': ['done']}
endfunction

function! s:setup() abort
  let g:iced#nrepl#connect#iced_command = 'ls'
  let g:iced#nrepl#connect#clj_command = 'ls'
  let g:iced#nrepl#connect#jack_in_command = 'ls -ltr'
endfunction

function! s:suite.auto_test() abort
  call s:ch.mock({
    \ 'status_value': ['fail', 'fail', 'open'],
    \ 'relay': funcref('s:auto_relay'),
    \ })
  call writefile([''], s:default_tmpfile)

  try
    silent execute printf(':e %s', s:default_tmpfile)
    call s:assert.equals(iced#nrepl#connect#auto(), v:true)

    let opened_args = iced#system#get('channel').get_opened_args()
    call s:assert.equals(opened_args['address'], '127.0.0.1:123456')
  finally
    silent execute printf(':e %s', s:project_deps_edn)
    call delete(s:default_tmpfile)
    call iced#nrepl#reset()
  endtry
endfunction

function! s:suite.auto_with_shadow_cljs_test() abort
  call s:ch.mock({
   \ 'status_value': ['fail', 'fail', 'open'],
   \ 'relay': funcref('s:auto_relay'),
   \ })
  call writefile([''], s:shadow_cljs_tmpfile)

  try
    silent execute printf(':e %s', s:shadow_cljs_tmpfile)
    call s:assert.equals(iced#nrepl#connect#auto(), v:true)

    let opened_args = iced#system#get('channel').get_opened_args()
    call s:assert.equals(opened_args['address'], '127.0.0.1:234567')
  finally
    silent execute printf(':e %s', s:project_deps_edn)
    call delete(s:shadow_cljs_tmpfile)
    call iced#nrepl#reset()
  endtry
endfunction

function! s:suite.jack_in_test() abort
  call s:setup()
  call s:timer.mock()
  call s:job.mock({'outs': ['nREPL server started']})
  call s:ch.mock({
     \ 'status_value': ['fail', 'fail',
     \                  'fail', 'fail',  'open'],
     \ 'relay': funcref('s:auto_relay'),
     \ })
  call writefile([''], s:default_tmpfile)

  try
    silent execute printf(':e %s', s:default_tmpfile)

    call iced#nrepl#connect#jack_in()

    let opened_args = iced#system#get('channel').get_opened_args()
    call s:assert.equals(opened_args['address'], '127.0.0.1:123456')
    call s:assert.equals(s:job.get_last_command(), 'ls -ltr')
  finally
    silent execute printf(':e %s', s:project_deps_edn)
    call delete(s:default_tmpfile)
    call iced#nrepl#reset()
  endtry
endfunction

function! s:suite.instant_test() abort
  call s:setup()
  call s:timer.mock()
  call s:job.mock({'outs': ['nREPL server started']})
  call s:ch.mock({
   \ 'status_value': ['fail', 'fail',
   \                  'fail', 'fail',
   \                  'fail', 'open'],
   \ 'relay': funcref('s:auto_relay'),
   \ })
  call writefile([''], s:default_tmpfile)

  try
    silent execute printf(':e %s', s:default_tmpfile)

    call iced#nrepl#connect#instant('')

    let opened_args = iced#system#get('channel').get_opened_args()
    call s:assert.equals(opened_args['address'], '127.0.0.1:123456')
    call s:assert.equals(s:job.get_last_command(), 'ls repl --instant')
  finally
    silent execute printf(':e %s', s:project_deps_edn)
    call delete(s:default_tmpfile)
    call iced#nrepl#reset()
  endtry
endfunction
