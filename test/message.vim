let s:suite  = themis#suite('iced.message')
let s:assert = themis#helper('assert')
let s:io = themis#helper('iced_io')
let s:notify = themis#helper('iced_notify')

function! s:suite.get_test() abort
  call s:assert.equals(iced#message#get('not_found'), 'Not found.')
  call s:assert.equals(iced#message#get('undefined'), 'Undefined %s.')
  call s:assert.equals(iced#message#get('undefined', 'foo'), 'Undefined foo.')
endfunction

function! s:suite.info_test() abort
  call s:io.mock()
  call iced#message#info_str('info test')
  call s:assert.equals(
        \ {'echomsg': {'hl': 'MoreMsg', 'text': 'info test'}},
        \ s:io.get_last_args(),
        \ )
endfunction

function! s:suite.echom_notify_test() abort
  let g:iced#message#enable_notify = v:true
  call s:io.mock()
  call s:notify.mock()

  call iced#message#info_str('notify test')
  call s:assert.equals(
        \ {'echomsg': {'hl': 'MoreMsg', 'text': 'notify test'}},
        \ s:io.get_last_args(),
        \ )
  call s:assert.equals(
        \ {'notify': {'option': {'title': 'Message'}, 'text': 'notify test'}},
        \ s:notify.get_last_args(),
        \ )

  let g:iced#message#enable_notify = v:false
endfunction
