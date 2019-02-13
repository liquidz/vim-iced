let s:suite  = themis#suite('iced.message')
let s:assert = themis#helper('assert')

function! s:suite.get_test() abort
  call s:assert.equals(iced#message#get('not_found'), 'Not found.')
  call s:assert.equals(iced#message#get('undefined'), 'Undefined %s.')
  call s:assert.equals(iced#message#get('undefined', 'foo'), 'Undefined foo.')
endfunction
