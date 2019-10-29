let s:suite  = themis#suite('iced.lint')
let s:assert = themis#helper('assert')
let s:ch = themis#helper('iced_channel')
let s:ex_cmd = themis#helper('iced_ex_cmd')
let s:sign = themis#helper('iced_sign')

let s:tempfile = tempname()

function! s:setup(lint_resp) abort " {{{
  call s:ex_cmd.mock()
  call s:sign.mock()
  call s:sign.unplace_all()
  call writefile([''], s:tempfile)

  let test = {}
  function! test.relay(msg, lint_resp) abort
    let res = {'status': ['done']}
    if a:msg['op'] ==# 'iced-lint-file'
      call extend(res, a:lint_resp)
    endif
    return res
  endfunction

  call s:ch.mock({
        \ 'status_value': 'open',
        \ 'relay': {msg -> test.relay(msg, a:lint_resp)}})
endfunction " }}}

function! s:teardown() abort " {{{
  call delete(s:tempfile)
endfunction " }}}

function! s:compare_lint_warning(w1, w2) abort " {{{
  let l1 = a:w1.lnum
  let l2 = a:w2.lnum

  if l1 == l2
    return 0
  elseif l1 > l2
    return 1
  endif

  return -1
endfunction " }}}

function! s:suite.current_file_test() abort
  call s:setup({'lint-warnings': [
        \ {'line': 1, 'path': s:tempfile},
        \ {'line': 3, 'path': s:tempfile},
        \ ]})
  if !iced#lint#is_enabled() | call iced#lint#toggle() | endif

  call iced#lint#current_file()
  let res = s:sign.list_in_current_buffer(s:tempfile)
  call sort(res, funcref('s:compare_lint_warning'))

  call s:assert.equals(res, [
        \ {'lnum': 1, 'file': s:tempfile, 'name': 'iced_lint', 'group': 'test_group'},
        \ {'lnum': 3, 'file': s:tempfile, 'name': 'iced_lint', 'group': 'test_group'},
        \ ])

  call s:teardown()
endfunction

function! s:suite.disabled_test() abort
  call s:setup({'lint-warnings': [{'line': 1, 'path': s:tempfile}]})
  if iced#lint#is_enabled() | call iced#lint#toggle() | endif

  call iced#lint#current_file()
  call s:assert.true(empty(s:sign.list_in_current_buffer(s:tempfile)))

  call s:teardown()
endfunction

function! s:suite.find_message_test() abort
  call s:setup({'lint-warnings': [{'line': 1, 'path': s:tempfile, 'msg': 'hello'}]})
  if !iced#lint#is_enabled() | call iced#lint#toggle() | endif

  call iced#lint#current_file()
  call s:assert.true(!empty(s:sign.list_in_current_buffer(s:tempfile)))

  call s:assert.equals(iced#lint#find_message(1, s:tempfile), 'hello')
  call s:assert.equals(iced#lint#find_message(2, s:tempfile), '')
  call s:assert.equals(iced#lint#find_message(1, 'non existing'), '')

  call s:teardown()
endfunction

function! s:suite.toggle_test() abort
  if iced#lint#is_enabled()
    call iced#lint#toggle()
    call s:assert.equals(iced#lint#is_enabled(), v:false)
  else
    call iced#lint#toggle()
    call s:assert.equals(iced#lint#is_enabled(), v:true)
  endif
endfunction

" vim:fdm=marker:fdl=0
