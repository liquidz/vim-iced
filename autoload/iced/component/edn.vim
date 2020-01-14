let s:save_cpo = &cpoptions
set cpoptions&vim

let s:edn = {
      \ 'job': '',
      \ 'jet': '',
      \ 'callback': '',
      \ 'available': v:false,
      \ }

function! s:edn.is_available() abort
  return self.available
endfunction

function! s:edn.decode(text, callback) abort
  if self.available
    let self.callback = a:callback
    call self.job.sendraw(self.jet, a:text)
  endif
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
  call iced#util#debug('start', 'edn')

  if !executable('jet')
    call iced#promise#sync(a:this['installer'].install, ['jet'], 10000)
  endif

  if !executable('jet')
    let s:edn.available = v:false
  else
    let s:edn.available = v:true
    let s:edn.job = a:this['job']
    let s:edn.jet = s:edn.job.start('jet --to json', {
          \ 'out_cb': funcref('s:out_callback', s:edn),
          \ 'drop': 'never',
          \ })
  endif

  return s:edn
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
