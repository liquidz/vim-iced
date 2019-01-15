let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {}
let s:Local = g:themis#vital.import('Vim.ScriptLocal')
let s:funcs = s:Local.sfuncs('autoload/iced/nrepl.vim')

function! s:build_test_channel(opt) abort
  let dummy = {'env': 'test', 'status_value': 'fail'}
  call extend(dummy, a:opt)

  function! dummy.open(address, options) abort
    let self['address'] = a:address
    let self['options'] = a:options
    return self
  endfunction

  function! dummy.close(handle) abort
    return
  endfunction

  function! dummy.status(handle) abort
    return self.status_value
  endfunction

  function! dummy.sendraw(handle, string) abort
    if has_key(self, 'relay') && type(self.relay) == v:t_func
      let sent_data = iced#di#get('bencode').decode(a:string)
      let resp_data = self.relay(sent_data)
      if has_key(sent_data, 'id') && !has_key(resp_data, 'id')
        let resp_data['id'] = sent_data['id']
      endif

      let resp_data = iced#di#get('bencode').encode(resp_data)
      let Cb = (has_key(self, 'callback') && type(self.callback) == v:t_func)
          \ ? self.callback : s:funcs.dispatcher
      call Cb(self, resp_data)
    elseif has_key(self, 'relay_raw') && type(self.relay_raw) == v:t_func
      let sent_data = iced#di#get('bencode').decode(a:string)
      let resp_data = self.relay_raw(sent_data)
      let Cb = (has_key(self, 'callback') && type(self.callback) == v:t_func)
          \ ? self.callback : s:funcs.dispatcher

      for resp_string in ((type(resp_data) == v:t_list) ? resp_data : [resp_data])
        call Cb(self, resp_string)
        sleep 10m
      endfor
    else
      return
    endif
  endfunction

  return dummy
endfunction

function! s:helper.register_test_builder(opt) abort
  call iced#di#register('channel', {_ -> s:build_test_channel(a:opt)})
endfunction

function! themis#helper#iced_channel#new(runner) abort
  return  deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
