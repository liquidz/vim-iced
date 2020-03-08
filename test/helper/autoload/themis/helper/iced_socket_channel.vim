let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {}
let s:Local = g:themis#vital.import('Vim.ScriptLocal')
let s:funcs = s:Local.sfuncs('autoload/iced/socket_repl.vim')

function! s:build_test_channel(opt) abort
  let dummy = {'env': 'test', 'status_value': 'fail'}
  call extend(dummy, a:opt)

  function! dummy.open(address, options) abort
    let self['address'] = a:address
    let self['options'] = a:options
    return self
  endfunction

  function! dummy.close(handle) abort
    let self['status_value'] = 'fail'
    return
  endfunction

  function! dummy.status(handle) abort
    if type(self.status_value) == v:t_list
      if empty(self.status_value)
        return 'fail'
      else
        return remove(self.status_value, 0)
      endif
    else
      return self.status_value
    endif
  endfunction

  function! dummy.sendraw(handle, string) abort
    if has_key(self, 'relay') && type(self.relay) == v:t_func
      let resp_data = self.relay(a:string)
      if type(resp_data) != v:t_string
        let resp_data = string(resp_data)
      endif
      let resp_data = resp_data . "\nuser=> "

      let Cb = (has_key(self, 'callback') && type(self.callback) == v:t_func)
          \ ? self.callback : s:funcs.dispatcher
      call Cb(self, resp_data)
    else
      return
    endif
  endfunction

  function! dummy.get_opened_args() abort
    return {
          \ 'address': self['address'],
          \ 'options': self['options'],
          \ }
	endfunction

  return dummy
endfunction

function! s:helper.mock(opt) abort
  call iced#system#set_component('channel', {'start': {_ -> s:build_test_channel(a:opt)}})
  call iced#system#set_component('future', {'start': 'iced#component#future#instant#start'})
endfunction

function! themis#helper#iced_socket_channel#new(runner) abort
  return deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
