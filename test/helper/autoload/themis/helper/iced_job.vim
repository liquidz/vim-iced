let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {
      \ 'id': -123,
      \ 'command': '',
      \ 'outs': [],
      \ }

function! s:helper.start(command, options) abort
  let self.command = a:command

  let OutCB = get(a:options, 'out_cb')
  if type(OutCB) == v:t_func
    for out in self.outs
      call OutCB(self.id, out)
    endfor
  endif

  return self.id
endfunction

function! s:helper.stop(_) abort
  return
endfunction

function! s:helper.out(command, callback) abort
  let self.command = a:command

  if type(a:callback) == v:t_func
    call a:callback(join(self.outs, ''))
  endif

  return self.id
endfunction

function! s:helper.is_job_id(x) abort
  return (a:x == self.id)
endfunction

function! s:helper.mock(...) abort
  let opts = get(a:, 1, {})
  let self.outs = get(opts, 'outs', [])
  call iced#system#set_component('job', {'start': {_ -> self}})
endfunction

function! s:helper.get_last_command() abort
  return self.command
endfunction

function! themis#helper#iced_job#new(runner) abort
  return deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
