let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {}

function! s:build(opt) abort
  let io = {'value': a:opt}

  function! io.input(prompt) abort
    return self.value.input
  endfunction

  return io
endfunction

function! s:helper.register_test_builder(opt) abort
  call iced#di#register('io', {_ -> s:build(a:opt)})
endfunction

" function! s:helper.get_last_args() abort
"   return self.last_args
" endfunction

function! themis#helper#iced_io#new(runner) abort
  return  deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
