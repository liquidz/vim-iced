let s:root_dir = expand('<sfile>:h:h')
let &runtimepath = &runtimepath .. ',' .. s:root_dir

let s:vim8 = iced#component#bencode#vim#start({})
let s:vim9 = iced#component#bencode#vim9#start({})

function! s:repeat(n, x) abort
  let res = []
  for i in range(a:n)
    call add(res, a:x)
  endfor
  return res
endfunction

function! s:zip_map(ks, vs) abort
  let l = min([len(a:ks), len(a:vs)])
  let res = {}
  for i in range(l)
     let res[string(a:ks[i])] = a:vs[i]
  endfor
  return res
endfunction

let s:n = 20
let s:child_data = {
      \ 'foo': join(s:repeat(s:n, 'bar'), ''),
      \ 'bar': s:repeat(s:n, ['baz']),
      \ }
let s:data = {
     \ 'foo': s:child_data,
     \ 'bar': s:repeat(s:n, s:child_data),
     \ 'baz': s:zip_map(range(s:n), s:repeat(s:n, s:child_data)),
     \ }
let s:data_encoded = s:vim9.encode(s:data)

let s:limit = 100
function! s:benchmark(label, f) abort
  let start = reltime()
  for x in range(s:limit)
    call a:f()
  endfor
  let seconds = reltimefloat(reltime(start))
  echo printf("%s: %f sec", a:label, seconds)
endfunction

call s:benchmark('Vim8 encode', { -> s:vim8.encode(s:data) })
call s:benchmark('Vim9 encode', { -> s:vim9.encode(s:data) })

call s:benchmark('Vim8 decode', { -> s:vim8.decode(s:data_encoded) })
call s:benchmark('Vim9 decode', { -> s:vim9.decode(s:data_encoded) })

:q
