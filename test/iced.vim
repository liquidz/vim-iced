let s:suite  = themis#suite('iced')
" let s:assert = themis#helper('assert')
" let s:ch = themis#helper('iced_channel')
"
" function! s:suite.eval_and_read_test() abort
"   let test = {'response': {}}
"   function! test.relay(msg) abort
"     return {'status': ['done'], 'value': 6}
"   endfunction
"
"   function! test.callback(resp) abort
"     let self['response'] = a:resp
"   endfunction
"
"   call s:ch.mock({'status_value': 'open', 'relay': test.relay})
"
"   let res = iced#eval_and_read('(+ 1 2 3)')
"   call s:assert.equals(res['value'], 6)
"
"   let res = iced#eval_and_read('(+ 1 2 3)', {x -> test.callback(x)})
"   call s:assert.equals(res, v:true)
"   call s:assert.equals(test.response['value'], 6)
" endfunction
