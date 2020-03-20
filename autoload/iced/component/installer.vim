let s:save_cpo = &cpoptions
set cpoptions&vim

let s:installer = {
      \ 'job': '',
      \ 'io': '',
      \ 'root_dir': expand('<sfile>:h:h:h:h'),
      \ 'install_dir_name': 'bin',
      \ 'installation_job': '',
      \ 'fullname': {'bb': 'babashka',
      \              'zprint-clj': 'zprint',
      \              },
      \ }

function! s:installed(fullname, callback, _) abort dict
  let info = self.job.info(self.installation_job)

  let ret = (info['exitval'] == 0) ? v:true : v:false
  if ret
    call iced#message#info('finish_to_install', a:fullname)
  else
    call iced#message#error('failed_to_install', a:fullname)
  endif

  return a:callback(ret)
endfunction

function! s:installer.install(name, ...) abort
  let Callback = get(a:, 1, {v -> v})
  let fullname = get(self.fullname, a:name, a:name)

  if executable(a:name)
    return Callback(v:true)
  endif

  let installer = printf('%s/installer/%s.sh', self.root_dir, a:name)
  let install_dir = printf('%s/%s', self.root_dir, self.install_dir_name)

  call iced#message#info('required_to_install', fullname)
  let res = self.io.input(iced#message#get('confirm_installation', fullname, install_dir))
  " for line break
  echom ' '
  if res !=# '' && res !=# 'y' && res !=# 'Y'
    return Callback(v:false)
  endif

  if !filereadable(installer)
    call iced#message#error('no_installer', fullname)
    return Callback(v:false)
  endif

  call iced#message#info('start_to_install', fullname)
  let self.installation_job = self.job.start(installer, {
        \ 'cwd': install_dir,
        \ 'close_cb': funcref('s:installed', [fullname, Callback], self)
        \ })
endfunction

function! iced#component#installer#start(this) abort
  call iced#util#debug('start', 'installer')
  let s:installer.job = a:this['job']
  let s:installer.io = a:this['io']
  return s:installer
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
