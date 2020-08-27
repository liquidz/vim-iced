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
      let sent_data = iced#system#get('bencode').decode(a:string)
      let resp_data = self.relay(sent_data)
      if has_key(sent_data, 'id') && !has_key(resp_data, 'id')
        let resp_data['id'] = sent_data['id']
      endif

      if get(sent_data, 'op') ==# 'describe' && !has_key(resp_data, 'ops')
        let resp_data['ops'] = {
              \ 'info': 1, 'complete': 1, 'test-var-query': 1, 'ns-path': 1,
              \ 'fn-refs': 1, 'fn-deps': 1,
              \ }
      endif

      let resp_data = iced#system#get('bencode').encode(resp_data)
      let Cb = (has_key(self, 'callback') && type(self.callback) == v:t_func)
          \ ? self.callback : s:funcs.dispatcher
      call Cb(self, resp_data)
    elseif has_key(self, 'relay_raw') && type(self.relay_raw) == v:t_func
      let sent_data = iced#system#get('bencode').decode(a:string)
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

  function! dummy.get_opened_args() abort
    return {
          \ 'address': self['address'],
          \ 'options': self['options'],
          \ }
	endfunction

  return dummy
endfunction

function! s:helper.mock(opt) abort
  call iced#nrepl#auto#enable_bufenter(v:false)
  call iced#cache#delete('supported_ops')
  call iced#system#set_component('bencode', {'start': 'iced#component#bencode#vim#start'})
  call iced#system#set_component('channel', {'start': {_ -> s:build_test_channel(a:opt)}})
  call iced#system#set_component('future', {'start': 'iced#component#future#instant#start'})
endfunction

function! themis#helper#iced_channel#new(runner) abort
  return deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
