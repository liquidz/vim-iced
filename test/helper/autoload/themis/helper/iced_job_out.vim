let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {
      \ 'last_command': '',
      \ 'outs': [],
      \ }

function! s:helper.mock(...) abort
  let opts = get(a:, 1, {})
  let self.outs = get(opts, 'outs', [])
  call iced#system#set_component('job_out', {'start': {_ -> self}})
endfunction

function! s:helper.get_last_command() abort
  return self.command
endfunction

function! s:helper.redir(command, callback) abort
  let self.last_command = a:command
  call a:callback(self.outs)
endfunction

function! themis#helper#iced_job_out#new(runner) abort
  return deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
