let s:save_cpo = &cpoptions
set cpoptions&vim

let s:edn = {
      \ 'job': '',
      \ 'jet': '',
      \ 'callback': '',
      \ }

function! s:edn.decode(text, callback) abort
  let self.callback = a:callback
  call self.job.sendraw(self.jet, a:text)
endfunction

function! s:out_callback(_, resp) abort dict
  try
    for resp in iced#util#ensure_array(a:resp)
      if resp ==# '' | continue | endif
      let res = json_decode(resp)
      if type(self.callback) == v:t_func
        call self.callback(res)
      endif
    endfor
  catch //
    echom printf('Failed to decode json: %s (%s)', a:resp, string(v:exception))
  endtry
endfunction

function! iced#component#edn#start(this) abort
  if !executable('jet')
    if !iced#promise#sync(a:this['installer'].install, ['jet'], 10000)
      return ''
    endif
  endif

  call iced#util#debug('start', 'edn')
  let s:edn.job = a:this['job']

  let s:edn.jet = s:edn.job.start('jet --to json', {
       \ 'out_cb': funcref('s:out_callback', s:edn),
       \ 'drop': 'never',
       \ })

  return s:edn
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
