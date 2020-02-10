let s:suite  = themis#suite('iced.nrepl.debug.default')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
let s:buf = themis#helper('iced_buffer')
let s:funcs = s:scope.funcs('autoload/iced/nrepl/debug/default.vim')

function! s:suite.apply_coordination_test() abort
  let g:iced_enable_popup_document = 'full'

  call s:buf.start_dummy(['|(aaa (bbb (ccc) ddd) eee)'])

  " aaa
  call cursor(1, 1)
  call iced#nrepl#debug#default#apply_coordination([0])
  call s:assert.equals(col('.'), 2)

  " bbb
  call cursor(1, 1)
  call iced#nrepl#debug#default#apply_coordination([1])
  call s:assert.equals(col('.'), 6)

  " ccc
  call cursor(1, 1)
  call iced#nrepl#debug#default#apply_coordination([1, 1])
  call s:assert.equals(col('.'), 11)

  " ddd
  call cursor(1, 1)
  call iced#nrepl#debug#default#apply_coordination([1, 2])
  call s:assert.equals(col('.'), 17)

  " eee
  call cursor(1, 1)
  call iced#nrepl#debug#default#apply_coordination([0, 2])
  call s:assert.equals(col('.'), 22)

  call s:buf.stop_dummy()
endfunction

function! s:suite.ensure_dict_test() abort
  call s:assert.equals(
        \ s:funcs.ensure_dict({'foo': 'bar'}),
        \ {'foo': 'bar'})

  call s:assert.equals(
        \ s:funcs.ensure_dict([{'foo': 'bar'}, {'bar': 'baz'}]),
        \ {'foo': 'bar', 'bar': 'baz'})

  call s:assert.equals(s:funcs.ensure_dict('string'), {})
  call s:assert.equals(s:funcs.ensure_dict(123), {})
endfunction
