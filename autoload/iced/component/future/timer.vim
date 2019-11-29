let s:save_cpo = &cpoptions
set cpoptions&vim

let s:future = {
      \ 'timer': '',
      \ 'delay': 10,
      \ }

function! s:future.do(fn) abort
  call self.timer.start(self.delay, {_ -> a:fn()})
endfunction

function! iced#component#future#timer#start(this) abort
  call iced#util#debug('start', 'timer future')
  let d = deepcopy(s:future)
  let d['timer'] = a:this.timer
  return d
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
