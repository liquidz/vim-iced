let s:suite  = themis#suite('iced.nrepl.navigate')
let s:assert = themis#helper('assert')
let s:buf = themis#helper('iced_buffer')
let s:ch = themis#helper('iced_channel')
let s:sel = themis#helper('iced_selector')
let s:vim = themis#helper('iced_vim')

let s:temp_file = tempname()

function! s:setup(opts) abort " {{{
  call writefile([''], s:temp_file)
  call s:sel.register_test_builder()
  call s:vim.register_test_builder()

  if has_key(a:opts, 'channel')
    call s:ch.register_test_builder({'status_value': 'open', 'relay': a:opts['channel']})
  endif

  if has_key(a:opts, 'buffer')
    call s:buf.start_dummy(a:opts['buffer'])
  endif
endfunction " }}}

function! s:teardown() abort " {{{
  call delete(s:temp_file)
  call s:buf.stop_dummy()
endfunction " }}}

function! s:suite.cycle_ns_test() abort
  call s:assert.equals(iced#nrepl#navigate#cycle_ns('foo.bar'), 'foo.bar-test')
  call s:assert.equals(iced#nrepl#navigate#cycle_ns('foo.bar-test'), 'foo.bar')
endfunction

let s:related_ns_test_ns_list = [
      \ 'foo.bar-test',
      \ 'foo.bar-spec',
      \ 'foo.bar.spec',
      \ 'foo.bar-dummy',
      \ 'foo.bar.baz',
      \ 'bar.baz',
      \ 'bar.baz-test',
      \ 'foo.baz.bar',
      \ ]

function! s:related_ns_relay(msg) abort
  if a:msg['op'] ==# 'ns-list'
    return {'status': ['done'], 'ns-list': s:related_ns_test_ns_list}
  elseif a:msg['op'] ==# 'ns-path'
    return {'status': ['done'], 'path': s:temp_file}
  else
    return {'status': ['done']}
  endif
endfunction

function! s:suite.related_ns_test() abort
  call s:setup({
        \ 'channel': funcref('s:related_ns_relay'),
        \ 'buffer': ['(ns foo.bar)', '|'],
        \ })

  call iced#nrepl#navigate#related_ns()
  let config = s:sel.get_last_config()

  call s:assert.equals(sort(copy(config['candidates'])), [
        \ 'foo.bar-spec',
        \ 'foo.bar-test',
        \ 'foo.bar.spec',
        \ 'foo.baz.bar',
        \ ])

  call config['accept']('', 'foo.bar-test')
  call s:assert.equals(s:vim.get_last_args()['exe'], printf(':edit %s', s:temp_file))

  call s:teardown()
endfunction

let s:test_test_vars = {
      \ 'baz-success-test': {'test': ''},
      \ 'baz-failure-test': {'test': ''},
      \ 'baz-test-fn': {}
      \ }

function! s:test_relay(msg) abort
  if a:msg['op'] ==# 'eval'
    return {'status': ['done'], 'value': '#''foo.bar/baz'}
  elseif a:msg['op'] ==# 'ns-vars-with-meta' && a:msg['ns'] ==# 'foo.bar-test'
    return {'status': ['done'], 'ns-vars-with-meta': s:test_test_vars}
  elseif a:msg['op'] ==# 'info'
    return {'status': ['done'], 'file': 'file:/path/to/file.clj', 'line': 1, 'column': 1}
  else
    return {'status': ['done']}
  endif
endfunction

function! s:suite.test_test() abort
  call s:setup({
        \ 'channel': funcref('s:test_relay'),
        \ 'buffer': ['(ns foo.bar)', '(defn baz [] "dummy"|)'],
        \ })

  call iced#nrepl#navigate#test()
  let config = s:sel.get_last_config()
  call s:assert.equals(sort(copy(config['candidates'])), [
        \ 'foo.bar-test/baz-failure-test',
        \ 'foo.bar-test/baz-success-test'])

  call config['accept']('', 'foo.bar-test/baz-success-test')
  call s:assert.equals(s:vim.get_last_args()['exe'], ':edit /path/to/file.clj')

  call s:teardown()
endfunction

" vim:fdm=marker:fdl=0
