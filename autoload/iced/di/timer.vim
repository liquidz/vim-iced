let s:save_cpo = &cpoptions
set cpoptions&vim

let s:timer = {}

function! s:timer.start(time, callback, ...) abort
  let options = get(a:, 1, {})
  return timer_start(a:time, a:callback, options)
endfunction

function! s:timer.stop(timer) abort
  return timer_stop(a:timer)
endfunction

function! iced#di#timer#build(container) abort
  return s:timer
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
