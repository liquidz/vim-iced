let s:save_cpo = &cpoptions
set cpoptions&vim

let g:iced#clojuredocs#export_edn_url = get(g:, 'iced#clojuredocs#export_edn_url',
      \ 'https://clojuredocs-edn.netlify.com/export.compact.edn')

let g:iced#clojuredocs#use_clj_docs_on_cljs =
      \ get(g:, 'iced#clojuredocs#use_clj_docs_on_cljs', v:false)

let s:default_cljs_ns_replace_map = {
      \ 'cljs.core': 'clojure.core',
      \ }
let g:iced#clojuredocs#cljs_ns_replace_map =
      \ get(g:, 'iced#clojuredocs#cljs_ns_replace_map', s:default_cljs_ns_replace_map)

function! s:refreshed(resp) abort
  if has_key(a:resp, 'err')
    let err = split(a:resp['err'], '\r\?\n')[0]
    return iced#message#error('failed_to_refresh', 'ClojureDocs', err)
  else
    return iced#message#info('finish_to_refresh', 'ClojureDocs')
  endif
endfunction

function! iced#clojuredocs#refresh() abort
  call iced#message#info('start_to_refresh', 'ClojureDocs')
  call iced#promise#call('iced#nrepl#op#cider#clojuredocs_refresh_cache',
        \                [g:iced#clojuredocs#export_edn_url])
        \.then(funcref('s:refreshed'))
endfunction

function! s:show_doc(resp) abort
  let res = []
  let doc = a:resp['clojuredocs']

  call add(res, printf('# %s/%s', doc['ns'], doc['name']))
  let args = map(copy(doc['arglists']), {_, v -> printf('(%s %s)', doc['name'], v)})
  call add(res, printf('`%s`', join(args, ' ')))
  call add(res, '')

  call add(res, printf('  %s', doc['doc']))
  call add(res, '')

  if !empty(doc['examples'])
    let egnum = len(doc['examples'])
    call add(res, printf('## %d %s', egnum, (egnum == 1) ? 'example' : 'examples'))
    call add(res, '')

    let cnt = 1
    for eg in doc['examples']
      call add(res, printf('* Example %d', cnt))
      call add(res, '```clojure')
      call add(res, trim(eg))
      call add(res, '```')

      call add(res, '')
      let cnt = cnt + 1
    endfor
  endif

  if !empty(doc['see-alsos'])
    call add(res, '## See also')
    let see_alsos = map(copy(doc['see-alsos']), {_, v -> printf('* %s', v)})
    call extend(res, see_alsos)
    call add(res, '')
  endif

  if !empty(doc['notes'])
    let notenum = len(doc['notes'])
    call add(res, printf('## %d %s', notenum, (notenum == 1) ? 'note' : 'notes'))
    call add(res, '')

    let cnt = 1
    for note in doc['notes']
      call add(res, printf('* Note %d', cnt))
      call add(res, printf('  %s', trim(note)))

      call add(res, '')
      let cnt = cnt + 1
    endfor
  endif

  call iced#buffer#document#open(join(res, "\n"), 'markdown')
endfunction

function! s:parse_qualified_symbol(qualified_symbol) abort
  let i = stridx(a:qualified_symbol, '/')
  if i < 0 | return {} | endif

  return {
        \ 'ns': a:qualified_symbol[0:i-1],
        \ 'name': a:qualified_symbol[i+1:],
        \ }
endfunction

function! s:construct_error_message() abort
  let resp = iced#cache#get('___clojuredocs-lookuping___', {})
  if has_key(resp, 'ns') && has_key(resp, 'name')
    let ns = resp['ns']
    let sym = printf('%s/%s', ns, resp['name'])

    if stridx(ns, 'cljs') == -1
      return iced#message#get('clojuredocs_not_found', sym)
    else
      return iced#message#get('clojuredocs_cljs_error', sym)
    endif
  else
    return iced#message#get('not_found')
  endif
endfunction

function! s:lookup(resp) abort
  let resp = copy(a:resp)
  if g:iced#clojuredocs#use_clj_docs_on_cljs
    let resp['ns'] = get(g:iced#clojuredocs#cljs_ns_replace_map, resp['ns'], resp['ns'])
  endif
  " NOTE: store ns-name and symbol-name for error message
  call iced#cache#set('___clojuredocs-lookuping___', resp)
  return iced#promise#call('iced#nrepl#op#cider#clojuredocs_lookup',
        \ [resp['ns'], resp['name'], g:iced#clojuredocs#export_edn_url])
endfunction

function! iced#clojuredocs#open(symbol) abort
  call iced#message#echom('fetching')
  call iced#promise#call('iced#nrepl#ns#in', [])
       \.then({_ -> (stridx(a:symbol, '/') > 0)
       \            ? s:parse_qualified_symbol(a:symbol)
       \            : iced#promise#call('iced#nrepl#var#get', [a:symbol])})
       \.then({resp -> iced#util#has_status(resp, 'no-info')
       \               ? iced#promise#reject('not-found')
       \               : s:lookup(resp)})
       \.then({resp -> iced#util#has_status(resp, 'no-doc')
       \               ? iced#message#error_str(s:construct_error_message())
       \               : s:show_doc(resp)},
       \      {err -> iced#message#error_str(s:construct_error_message())})
       \.catch({err -> iced#message#error('unexpected_error', err)})
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
