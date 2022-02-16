let s:save_cpo = &cpoptions
set cpoptions&vim

let s:V = vital#iced#new()
let s:I = s:V.import('Data.String.Interpolation')

let s:kondo = {
      \ 'job_out': '',
      \ 'cache_dir': '',
      \ 'user_dir': '',
      \ }

function! s:temp_name(name) abort
  return printf('%s.tmp', a:name)
endfunction

function! s:rename_temp_file(base_name, ...) abort
  call rename(s:temp_name(a:base_name), a:base_name)
endfunction

function! s:kondo.namespace_definitions_cache_name() abort
  return printf('%s/%s_ns_definitions.json', self.cache_dir, substitute(self.user_dir, '/', '_', 'g'))
endfunction

function! s:kondo.namespace_usages_cache_name() abort
  return printf('%s/%s_ns_usages.json', self.cache_dir, substitute(self.user_dir, '/', '_', 'g'))
endfunction

function! s:kondo.local_definitions_cache_name() abort
  return printf('%s/%s_local_definitions.json', self.cache_dir, substitute(self.user_dir, '/', '_', 'g'))
endfunction

function! s:kondo.local_usages_cache_name() abort
  return printf('%s/%s_local_usages.json', self.cache_dir, substitute(self.user_dir, '/', '_', 'g'))
endfunction

function! s:kondo.keywords_cache_name() abort
  return printf('%s/%s_keywords.json', self.cache_dir, substitute(self.user_dir, '/', '_', 'g'))
endfunction

function! s:kondo.protocol_impls_cache_name() abort
  return printf('%s/%s_protocols.json', self.cache_dir, substitute(self.user_dir, '/', '_', 'g'))
endfunction

function! s:kondo.analyzed(cache_name, callback) abort
  let partials = {
        \ 'namespace-usages': self.namespace_usages_cache_name(),
        \ 'namespace-definitions': self.namespace_definitions_cache_name(),
        \ 'protocol-impls': self.protocol_impls_cache_name(),
        \ }
  if g:iced_enable_clj_kondo_local_analysis
    call extend(partials, {
          \ 'local-usages': self.local_usages_cache_name(),
          \ 'locals': self.local_definitions_cache_name(),
          \ 'keywords': self.keywords_cache_name(),
          \ })
  endif

  if executable('jq')
    for key in keys(partials)
      let partial_cache_name = get(partials, key)
      let command = ['sh', '-c', printf('jq -c ''.analysis."%s"'' %s > %s',
            \ key,
            \ a:cache_name,
            \ s:temp_name(partial_cache_name),
            \ )]

      call self.job_out.redir(command, funcref('s:rename_temp_file', [partial_cache_name]))
    endfor
  elseif executable('jet')
    for key in keys(partials)
      let partial_cache_name = get(partials, key)
      let command = ['sh', '-c', printf('cat %s | jet --from json --to json --query ''["analysis" "%s"]'' > %s',
            \ a:cache_name,
            \ key,
            \ s:temp_name(partial_cache_name),
            \ )]
      call self.job_out.redir(command, funcref('s:rename_temp_file', [partial_cache_name]))
    endfor
  endif

  return a:callback()
endfunction

function! s:kondo.namespace_definitions() abort
  let cache_name = self.namespace_definitions_cache_name()
  if !filereadable(cache_name) | return [] | endif

  let res = readfile(cache_name)
  if empty(res) | return [] | endif

  return json_decode(res[0])
endfunction

function! s:kondo.namespace_usages() abort
  let cache_name = self.namespace_usages_cache_name()
  if !filereadable(cache_name) | return [] | endif

  let res = readfile(cache_name)
  if empty(res) | return [] | endif

  return json_decode(res[0])
endfunction

function! s:kondo.local_definitions() abort
  let cache_name = self.local_definitions_cache_name()
  if !filereadable(cache_name) | return [] | endif

  let res = readfile(cache_name)
  if empty(res) | return [] | endif

  return json_decode(res[0])
endfunction

function! s:kondo.local_usages() abort
  let cache_name = self.local_usages_cache_name()
  if !filereadable(cache_name) | return [] | endif

  let res = readfile(cache_name)
  if empty(res) | return [] | endif

  return json_decode(res[0])
endfunction

function! s:kondo.keywords() abort
  let cache_name = self.keywords_cache_name()
  if !filereadable(cache_name) | return [] | endif

  let res = readfile(cache_name)
  if empty(res) | return [] | endif

  return json_decode(res[0])
endfunction

function! s:kondo.protocols() abort
  let cache_name = self.protocol_impls_cache_name()
  if !filereadable(cache_name) | return [] | endif

  let res = readfile(cache_name)
  return json_decode(res[0])
endfunction

function! iced#component#clj_kondo#json#start(this) abort
  call iced#util#debug('start', 'clj-kondo.json')
  let s:kondo.job_out = a:this['job_out']
  let s:kondo.cache_dir = iced#cache#directory()

  let user_dir = iced#nrepl#system#user_dir()
  let s:kondo.user_dir = empty(user_dir) ? expand('%:p:h') : user_dir
  let s:kondo.db_name = printf('%s/%s.db', s:kondo.cache_dir, substitute(s:kondo.user_dir, '/', '_', 'g'))
  return s:kondo
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
