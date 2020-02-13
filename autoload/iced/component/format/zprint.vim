let s:save_cpo = &cpoptions
set cpoptions&vim

let s:default_zprint_option = '{:style [:community :respect-nl]}'
let g:iced#format#zprint_option = get(g:, 'iced#format#zprint_option', s:default_zprint_option)

function! iced#component#format#zprint#start(this) abort
  call iced#util#debug('start', 'format zprint')

  if !executable('zprint')
    call iced#promise#sync(a:this['installer'].install, ['zprint'], 30000)
  endif

  let d = deepcopy(a:this.format_ni)
  let d.command = ['zprint', g:iced#format#zprint_option]
  return d
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
