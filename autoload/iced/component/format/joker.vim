let s:save_cpo = &cpoptions
set cpoptions&vim

function! iced#component#format#joker#start(this) abort
  call iced#util#debug('start', 'format joker')

  " TODO
  " if !executable('joker')
  "   call iced#promise#sync(a:this['installer'].install, ['joker'], 30000)
  " endif

  let d = deepcopy(a:this.format_native_image)
  let d.command = ['joker', '--format', '-']
  return d
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
