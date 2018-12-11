let s:suite  = themis#suite('iced.qf')
let s:assert = themis#helper('assert')

function! s:suite.is_opened_test()
  call s:assert.false(iced#qf#is_opened())
endfunction
