let s:save_cpo = &cpoptions
set cpoptions&vim

let g:iced#clojuredocs#export_edn_url = get(g:, 'iced#clojuredocs#export_edn_url',
    \ 'https://clojuredocs-edn.netlify.com/export.edn')

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

    for eg in doc['examples']
      let editors = get(eg, 'editors', [])
      let editors = [eg['author']['login']] + map(copy(editors), {_, v -> v['login']})
      call add(res, printf('* %s', join(uniq(editors), ', ')))

      call add(res, '```clojure')
      call add(res, eg['body'])
      call add(res, '```')

      call add(res, '')
    endfor
  endif

  if !empty(doc['see-alsos'])
    call add(res, '## See also')
    let see_alsos = map(copy(doc['see-alsos']), {_, v -> v['to-var']})
    call map(see_alsos, {_, v -> printf('* %s/%s', v['ns'], v['name'])})
    call extend(res, see_alsos)
    call add(res, '')
  endif

  if !empty(doc['notes'])
    let notenum = len(doc['notes'])
    call add(res, printf('## %d %s', notenum, (notenum == 1) ? 'note' : 'notes'))
    call add(res, '')

    for note in doc['notes']
      call add(res, printf('* %s', note['author']['login']))
      call add(res, printf('  %s', note['body']))
      call add(res, '')
    endfor
  endif

  call iced#buffer#document#open(join(res, "\n"), 'markdown')
endfunction

function! iced#clojuredocs#open(symbol) abort
  call iced#message#echom('fetching')
  call iced#promise#call('iced#nrepl#ns#in', [])
       \.then({_ -> iced#promise#call('iced#nrepl#var#get', [a:symbol])})
       \.then({resp -> iced#util#has_status(resp, 'no-info')
       \               ? iced#promise#reject('not-found')
       \               : iced#promise#call('iced#nrepl#op#cider#clojuredocs_lookup',
       \                   [resp['ns'], resp['name'], g:iced#clojuredocs#export_edn_url])})
       \.then({resp -> iced#util#has_status(resp, 'no-document')
       \               ? iced#message#error('not_found')
       \               : s:show_doc(resp)},
       \      {err -> iced#message#error('not_found')})
       \.catch({err -> iced#message#error('unexpected_error', err)})
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
