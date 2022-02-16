let s:save_cpo = &cpoptions
set cpoptions&vim

let s:V = vital#iced#new()
let s:I = s:V.import('Data.String.Interpolation')

let s:kondo = {
      \ 'job_out': '',
      \ 'cache_dir': '',
      \ 'user_dir': '',
      \ 'db_name': '',
      \ }

function! s:temp_name(name) abort
  return printf('%s.tmp', a:name)
endfunction

function! s:rename_temp_file(base_name) abort
  call rename(s:temp_name(a:base_name), a:base_name)
endfunction

function! s:imported_to_sqlite(db_name, rm_files) abort
  call s:rename_temp_file(a:db_name)
  for path in a:rm_files
    call delete(path)
  endfor
endfunction

function! s:kondo.analyzed(cache_name, callback) abort
  let tmp = tempname()
  let shell_file = printf('%s.sh', tmp)
  let sql_file = printf('%s.sql', tmp)
  let key_arr = ['var-definitions', 'var-usages', 'namespace-usages', 'namespace-definitions', 'local-usages', 'locals', 'keywords', 'protocol-impls']
  let rm_files = [shell_file, sql_file]

  for key in key_arr
    " Create CSV for importing to SQLite
    let csv_file = printf('%s%s.csv', tmp, key)
    let rm_files += [csv_file]
    call writefile([printf('jq -r ''.analysis."%s" | .[] | [. | tostring] | @csv'' %s > %s',
          \                key, a:cache_name, csv_file)],
          \ shell_file, 'a')

    " Create SQL to import CSV
    let table_name = substitute(key, '-', '_', 'g')
    call writefile([printf('CREATE TABLE %s (json TEXT);', table_name),
          \         printf('.import %s%s.csv %s', tmp, key, table_name)],
          \ sql_file, 'a')
  endfor

  call writefile([printf('sqlite3 %s < %s', s:temp_name(self.db_name), sql_file)],
        \ shell_file, 'a')
  call self.job_out.redir(['sh', shell_file], {_ -> s:analyzed__analyzed(self.db_name, rm_files, a:callback)})
endfunction

function! s:analyzed__analyzed(db_name, rm_files, callback) abort
  call s:imported_to_sqlite(a:db_name, a:rm_files)
  return a:callback()
endfunction

function! s:kondo.references(ns_name, var_name) abort
  if ! filereadable(self.db_name) | return [] | endif

  " Remove quote if exists
  let var_name = trim(a:var_name, "'")
  let sql = s:I.interpolate('select * from var_usages where json_extract(json, "$.to") = "${ns_name}" and json_extract(json, "$.name") = "${var_name}"',
        \ {'ns_name': a:ns_name,
        \  'var_name': var_name})
  let res = trim(system(printf('sqlite3 %s ''%s''', self.db_name, sql)))

  if empty(res) | return [] | endif
  let res = printf('[%s]', substitute(res, '\n', ',', 'g'))
  return json_decode(res)
endfunction

function! s:kondo.ns_aliases(...) abort
  let from_ns = get(a:, 1, '')
  let where = empty(from_ns)
        \ ? ''
        \ : s:I.interpolate('and json_extract(json, "$.from") = "${from_ns}"', {'from_ns': from_ns})
  let sql = s:I.interpolate(
        \ 'select group_concat(json_str) from (select 1 as id, json_quote(json_extract(json, "$.alias")) || ": [" || group_concat(distinct json_quote(json_extract(json, "$.to"))) || "]" as json_str from namespace_usages where json_extract(json, "$.alias") is not null and json_type(json, "$.alias") = "text" ${where} group by json_extract(json, "$.alias")) group by id',
        \ {'where': where})
  let res = trim(system(printf('sqlite3 %s ''%s''', self.db_name, sql)))

  if empty(res) | return {} | endif
  let res = printf('{%s}', res)
  return json_decode(res)
endfunction

function! s:kondo.local_definition(filename, row, name) abort
  if ! filereadable(self.db_name) | return {} | endif

  " Remove quote if exists
  let name = trim(a:name, "'")
  let sql = s:I.interpolate('select locals.json from local_usages inner join locals on json_extract(locals.json, "$.id") = json_extract(local_usages.json, "$.id") where json_extract(local_usages.json, "$.filename") = "${filename}" and json_extract(local_usages.json, "$.row") = ${row} and json_extract(local_usages.json, "$.name") = "${name}" limit 1',
        \ {'filename': a:filename, 'row': a:row, 'name': name})
  let res = trim(system(printf('sqlite3 %s ''%s''', self.db_name, sql)))
  return (empty(res) ? {} : json_decode(res))
endfunction

function! s:kondo.keyword_usages(kw_name) abort
  if ! filereadable(self.db_name) | return {} | endif

  let sql = ''
  let idx = stridx(a:kw_name, '/')

  if idx != -1
    let sql = s:I.interpolate('select keywords.json from keywords where json_extract(keywords.json, "$.ns") = "${ns}" and json_extract(keywords.json, "$.name") = "${name}"',
        \ {'ns': a:kw_name[0:idx-1],
        \  'name': a:kw_name[idx+1:]})
  else
    let sql = s:I.interpolate('select keywords.json from keywords where json_extract(keywords.json, "$.name") = "${name}"',
        \ {'name': a:kw_name})
  endif

  let res = trim(system(printf('sqlite3 %s ''%s''', self.db_name, sql)))
  if empty(res) | return [] | endif
  let res = printf('[%s]', substitute(res, '\n', ',', 'g'))
  return json_decode(res)
endfunction

function! s:kondo.keyword_definition(filename, kw_name) abort
  if ! filereadable(self.db_name) | return {} | endif

  let sql = ''
  let kw_name = substitute(a:kw_name, '^:\+', '', 'g')
  let idx = stridx(kw_name, '/')

  if idx != -1
    let sql = s:I.interpolate('select * from keywords where json_extract(json, "$.ns") || "/" || json_extract(json, "$.name") in (select json_extract(json, "$.ns") || "/" || json_extract(json, "$.name") from keywords where json_extract(json, "$.filename") = "${filename}" and json_extract(json, "$.alias") = "${alias}" and json_extract(json, "$.name") = "${name}") and json_extract(json, "$.reg") is not null',
          \ {'filename': a:filename,
          \  'alias': kw_name[0:idx-1],
          \  'name': kw_name[idx+1:]})
  else
    let sql = s:I.interpolate('select * from keywords where json_extract(json, "$.filename") = "${filename}" and json_extract(json, "$.alias") is null and json_extract(json, "$.name") = "${name}" and json_extract(json, "$.reg") is not null',
          \ {'filename': a:filename,
          \  'name': kw_name})
  endif

  let res = trim(system(printf('sqlite3 %s ''%s''', self.db_name, sql)))
  if empty(res) | return [] | endif
  let res = substitute(res, '\n', ',', 'g')
  return json_decode(res)
endfunction

function! s:kondo.ns_path(ns_name) abort
  if ! filereadable(self.db_name) | return '' | endif
  let sql = printf(
        \ 'select json_extract(namespace_definitions.json, "$.filename") from namespace_definitions where json_extract(namespace_definitions.json, "$.name") = "%s"',
        \ a:ns_name,
        \ )
  let res = trim(system(printf('sqlite3 %s ''%s''', self.db_name, sql)))
  if empty(res) | return '' | endif
  return res
endfunction

function! s:kondo.ns_list() abort
  if ! filereadable(self.db_name) | return [] | endif
  let sql = 'select json_quote(json_extract(namespace_definitions.json, "$.name")) from namespace_definitions'

  let res = trim(system(printf('sqlite3 %s ''%s''', self.db_name, sql)))
  if empty(res) | return [] | endif
  let res = printf('[%s]', substitute(res, '\n', ',', 'g'))
  return json_decode(res)
endfunction

function! s:kondo.protocol_implementations(protocol_ns, protocol_name, method_name) abort
  if ! filereadable(self.db_name) | return [] | endif
  let sql = printf('select * from protocol_impls where json_extract(protocol_impls.json, "$.protocol-ns") = "%s" and json_extract(protocol_impls.json, "$.protocol-name") = "%s"',
        \ a:protocol_ns,
        \ a:protocol_name,
        \ )
  if !empty(a:method_name)
    let sql = printf('%s and json_extract(protocol_impls.json, "$.method-name") = "%s"',
          \ sql,
          \ a:method_name,
          \ )
  endif

  let res = trim(system(printf('sqlite3 %s ''%s''', self.db_name, sql)))
  if empty(res) | return [] | endif
  let res = printf('[%s]', substitute(res, '\n', ',', 'g'))
  return json_decode(res)
endfunction

function! iced#component#clj_kondo#sqlite#start(this) abort
  call iced#util#debug('start', 'clj-kondo.sqlite')
  let s:kondo.job_out = a:this['job_out']
  let s:kondo.cache_dir = iced#cache#directory()

  let user_dir = iced#nrepl#system#user_dir()
  let s:kondo.user_dir = empty(user_dir) ? expand('%:p:h') : user_dir
  let s:kondo.db_name = printf('%s/%s.db', s:kondo.cache_dir, substitute(s:kondo.user_dir, '/', '_', 'g'))

  return s:kondo
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
