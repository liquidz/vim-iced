let s:save_cpo = &cpoptions
set cpoptions&vim

let s:prepl = {
      \ 'socket_repl': '',
      \ 'edn': '',
      \ }

function! s:reader(callback, res) abort
  if ! has_key(a:res, 'tag') | return | endif

  call iced#util#debug('<<< edn', a:res)

  let tag = a:res['tag']
  let d = {}
  if tag ==# 'ret'
    let d['value'] = a:res['val']
    if get(a:res, 'exception', v:false)
      let d['out'] = a:res['val']
    endif
  elseif tag ==# 'out'
    let d['out'] = a:res['val']
  elseif tag ==# 'tap'
    let d['out'] = printf('%s ;; <= tapped', a:res['val'])
  endif

  if !empty(d)
    call a:callback(d)
  endif
endfunction

function! s:handler(text, callback) dict abort
  call self.edn.decode(a:text, funcref('s:reader', [a:callback]))
endfunction

function! s:connect(port) dict abort
  return self.socket_repl.connect(a:port, {
        \ 'prompt': "\n",
        \ 'handler': funcref('s:handler', self),
        \ })
endfunction

function! iced#component#repl#prepl#start(this) abort
  call iced#util#debug('start', 'prepl')

  let s:prepl.socket_repl = a:this['socket_repl']
  let s:prepl.edn = a:this['edn']
  if !s:prepl.edn.is_available() | return '' | endif

  let d = deepcopy(a:this['socket_repl'])
  let d['connect'] = funcref('s:connect', s:prepl)
  return d
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
