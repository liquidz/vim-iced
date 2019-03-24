let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {}
let s:Local = g:themis#vital.import('Vim.ScriptLocal')
let s:funcs = s:Local.sfuncs('autoload/iced/nrepl.vim')
let s:errbuf = {'open': {-> ''}, 'show': {text -> ''}}

function! s:build_test_state(opt) abort
  let st = {
        \ 'connected_value': get(a:opt, 'is_connected', v:true),
        \ 'relay': ''}

  if has_key(a:opt, 'relay') && type(a:opt.relay) == v:t_func
    let st['relay'] = a:opt.relay
  endif

  function! st.is_connected() abort
    return self.connected_value
  endfunction

  function! st.send(message) abort
    let resp_data = (type(self.relay) == v:t_func)
          \ ? self.relay(a:message)
          \ : {'status': ['done']}

    if has_key(a:message, 'id') && !has_key(resp_data, 'id')
      let resp_data['id'] = a:message['id']
    endif
    call s:funcs.dispatcher(resp_data)
  endfunction

  return st
endfunction

function! s:helper.start_test_state(opt) abort
  call iced#state#define('error_buffer', {'start': {_ -> s:errbuf}})
  call iced#state#define('nrepl', {
        \ 'start': {_ -> s:build_test_state(a:opt)},
        \ 'require': ['quickfix', 'ex_cmd', 'error_buffer'],
        \ })
  call iced#state#start_by_name('nrepl')
endfunction

function! themis#helper#iced_nrepl#new(runner) abort
  return  deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
