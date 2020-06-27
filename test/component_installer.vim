let s:suite  = themis#suite('iced.component.installer')
let s:assert = themis#helper('assert')
let s:io = themis#helper('iced_io')
let s:job = themis#helper('iced_job')

function! s:setup() abort
  call s:job.mock()
  " Skip confirmation
  call s:io.mock({'input': 'y'})
endfunction

function! s:suite.install_test() abort
  call s:setup()

  let s:installer = iced#system#get('installer')
  let res = iced#promise#sync(s:installer.install, ['zprint-clj'])

  call s:assert.equals(res, v:true)
  call s:assert.true(stridx(s:job.get_last_command(), 'zprint-clj.sh') != -1)
endfunction

function! s:suite.complete_test() abort
  let g:vim_iced_home = expand('<sfile>:p:h')
  let res = iced#component#installer#complete(0, 0, 0)
  let res = split(res, '\n')

  call s:assert.true(len(res) > 0)
endfunction
