let s:suite  = themis#suite('iced.nrepl.navigate')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:buf = themis#helper('iced_buffer')
let s:ch = themis#helper('iced_channel')
let s:sel = themis#helper('iced_selector')
let s:ex_cmd = themis#helper('iced_ex_cmd')
let s:qf = themis#helper('iced_quickfix')

let s:funcs = s:scope.funcs('autoload/iced/nrepl/navigate.vim')
let s:temp_file = tempname()

function! s:setup(opts) abort " {{{
  call writefile([''], s:temp_file)
  call s:sel.register_test_builder()
  call s:ex_cmd.register_test_builder()
  call s:qf.register_test_builder()
  call iced#nrepl#change_current_session('clj')

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
  if a:msg['op'] ==# 'iced-project-ns-list'
    return {'status': ['done'], 'project-ns-list': s:related_ns_test_ns_list}
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
  call s:assert.equals(s:ex_cmd.get_last_args()['exe'], printf(':edit %s', s:temp_file))

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
  call s:assert.equals(s:ex_cmd.get_last_args()['exe'], ':edit /path/to/file.clj')

  call s:teardown()
endfunction

function! s:find_var_references_relay(msg) abort
  let op = a:msg['op']
  if op ==# 'info'
    return {'status': ['done'], 'ns': 'foo', 'name': 'bar'}
  elseif op ==# 'iced-find-var-references'
    return {'status': ['done'], 'var-references': [
          \ {'filename': '/path/to/foo.txt', 'lnum': 12, 'text': 'hello'},
          \ {'filename': '/path/to/bar.txt', 'lnum': 34, 'text': 'world'}]}
  elseif op ==# 'eval'
    return {'status': ['done'], 'value': json_encode({
          \ 'user-dir': '/path/to/user/dir',
          \ 'file-separator': '/'})}
  else
    return {'status': ['done']}
  endif
endfunction

function! s:suite.find_var_references_test() abort
  let g:iced#var_references#cache_dir = fnamemodify(s:temp_file, ':h')
  call s:setup({'channel': funcref('s:find_var_references_relay')})
  let cache_path = s:funcs.reference_cache_path('foo', 'bar')

  call s:assert.false(filereadable(cache_path))

  call iced#nrepl#navigate#find_var_references('foo/bar', '')
  let qf_list = s:qf.get_last_args()['list']
  call s:assert.equals(qf_list, [
        \ {'filename': '/path/to/foo.txt', 'lnum': 12, 'text': 'hello'},
        \ {'filename': '/path/to/bar.txt', 'lnum': 34, 'text': 'world'}])

  " cache file existence
  call s:assert.true(filereadable(cache_path))
  call s:assert.equals(iced#util#read_var(cache_path), qf_list)

  " find var references with cache file
  let cache_test_data = [
        \ {'filename': '/path/to/baz.txt', 'lnum': 56, 'text': 'zzz'}]
  call iced#util#save_var(cache_test_data, cache_path)
  call iced#nrepl#navigate#find_var_references('foo/bar', '')
  call s:assert.equals(s:qf.get_last_args()['list'], cache_test_data)

  call s:teardown()
endfunction

" vim:fdm=marker:fdl=0
