let s:save_cpo = &cpoptions
set cpoptions&vim

let s:default_zprint_option = '{:style [:community :respect-nl]}'
let g:iced#format#zprint_option = get(g:, 'iced#format#zprint_option', s:default_zprint_option)

function! iced#component#format#zprint#start(this) abort
  call iced#util#debug('start', 'format zprint')

  " NOTE: macOS has a same named command, so add '-clj' postfix
  if !executable('zprint-clj')
    call iced#promise#sync(a:this['installer'].install, ['zprint-clj'], 30000)
  endif

  let d = deepcopy(a:this.format_native_image)
  let d.command = ['zprint-clj', g:iced#format#zprint_option]
  return d
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
