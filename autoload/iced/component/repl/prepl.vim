let s:save_cpo = &cpoptions
set cpoptions&vim

let s:prepl = {
      \ 'socket_repl': '',
      \ 'job': '',
      \ 'jet': '',
      \ 'callback': '',
      \ }

function! s:reader(_, resp) abort
  try
    let res = json_decode(a:resp)
    if ! has_key(res, 'tag') | return | endif

    call iced#util#debug('<<< edn', res)

    let tag = res['tag']
    let d = {}
    if tag ==# 'ret'
      let d['value'] = res['val']
      if get(res, 'exception', v:false)
        let d['out'] = res['val']
      endif
    elseif tag ==# 'out'
      let d['out'] = res['val']
    elseif tag ==# 'tap'
      let d['out'] = printf('%s ;; <= tapped', res['val'])
    endif

    if !empty(d)
      call s:prepl['callback'](d)
    endif

  catch //
    echom printf('Failed to decode json: %s (%s)', a:resp, string(v:exception))
  endtry
endfunction

function! s:handler(text, callback) dict abort
  let self.callback = a:callback
  call self.job.sendraw(self.jet, a:text)
endfunction

function! s:connect(port) dict abort
  if !executable('jet')
    call iced#message#error('not_executable', 'jet')
    return v:false
  endif

  let self.jet = self.job.start('jet --to json', {
       \ 'out_cb': funcref('s:reader'),
       \ 'drop': 'never',
       \ })

  return self.socket_repl.connect(a:port, {
        \ 'prompt': "\n",
        \ 'handler': funcref('s:handler', self),
        \ })
endfunction

function! iced#component#repl#prepl#start(this) abort
  call iced#util#debug('start', 'prepl')

  let s:prepl.socket_repl = a:this['socket_repl']
  let s:prepl.job = a:this['job']

  let d = deepcopy(a:this['socket_repl'])
  let d['connect'] = funcref('s:connect', s:prepl)
  return d
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
