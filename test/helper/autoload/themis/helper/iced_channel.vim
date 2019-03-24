let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {}
let s:Local = g:themis#vital.import('Vim.ScriptLocal')
let s:funcs = s:Local.sfuncs('autoload/iced/nrepl.vim')

function! s:ensure_list(x) abort
  return type(a:x) == v:t_list ? a:x : [a:x]
endfunction

function! s:build_test_state(params, opt) abort
  let ch = {'status_value': get(a:opt, 'status_value', 'open'),
        \   'is_raw': get(a:opt, 'is_raw', v:false),
        \   'relay': get(a:opt, 'relay', ''),
        \   'callback': '',
        \   'state': {'bencode': a:params.require.bencode},
        \   }

  function! ch.open(address, options) abort
    let self['callback'] = get(a:options, 'callback', '')
    return {}
  endfunction

  function! ch.close(handler) abort
    return
  endfunction

  function! ch.status(handler) abort
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

  function! ch.sendraw(handler, string) abort
    if type(self.callback) == v:t_func && type(self.relay) == v:t_func
      let msg = self.state.bencode.decode(a:string)
      let resp_data = self.relay(msg)

      if type(resp_data) == v:t_dict && !has_key(resp_data, 'id') && has_key(msg, 'id')
        let resp_data['id'] = msg['id']
      endif

      let resp_data = self.is_raw ? resp_data : self.state.bencode.encode(resp_data)
      for resp in s:ensure_list(resp_data)
        call self.callback({}, resp)
      endfor
    endif
  endfunction

  return ch
endfunction

function! s:helper.define_test_state(opt) abort
  call iced#state#define('bencode', {'start': {v -> iced#state#bencode#vim#start(v)}})
  call iced#state#define('channel', {
        \ 'start': {params -> s:build_test_state(params, a:opt)},
        \ 'require': ['bencode']})
  call iced#state#define('nrepl', {
        \ 'start': function('iced#state#nrepl#start'),
        \ 'stop': function('iced#state#nrepl#stop'),
        \ 'require': ['bencode', 'channel']})
endfunction

function! s:helper.start_test_state(opt) abort
  call self.define_test_state(a:opt)
  call iced#state#start_by_name('nrepl', {
        \ 'port': 1234,
        \ 'callback': s:funcs.dispatcher})
endfunction

function! themis#helper#iced_channel#new(runner) abort
  return  deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
