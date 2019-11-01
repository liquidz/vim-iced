let s:save_cpo = &cpoptions
set cpoptions&vim

let s:find = {'job': ''}

function! s:find.file(dir, name, callback) abort
  let cmd = ''
  if executable('fd')
    let cmd = printf('fd -p -t f -c never ''%s'' %s', a:name, a:dir)
  else
    let cmd = printf('find %s -type f -not -path "*/.git/*" -not -path "*/target/*" -name ''%s'' | grep ''%s''',
         \ a:dir, fnamemodify(a:name, ':t'), fnamemodify(a:name, ':h'))
  endif
  let cmd = cmd . ' | head -n 1'
  call self.job.out(['sh', '-c', cmd], a:callback)
endfunction

function! iced#component#find#start(this) abort
  call iced#util#debug('start', 'find')
  let d = deepcopy(s:find)
  let d['job'] = a:this.job
  return d
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
