#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter



""
" Return |dictionary| similar to what JavaScript do for URLs
"
" Parameter:~
" - {data} |string| to parse into URL components
"
" TODO:~
" - Maybe enable user/pass auth via -> https://serverfault.com/questions/371907/can-you-pass-user-pass-for-http-basic-authentication-in-url-parameters
"
" - Maybe investigate if "hash" is before or after search parameters
function! proompter#url#FromString(data) abort
  if type(a:data) != v:t_string
    throw 'ProompterError data is not a string'
  endif

  let l:index = 0
  let l:result = {
        \   'href': '',
        \   'origin': '',
        \   'protocol': '',
        \   'username': '',
        \   'password': '',
        \   'host': '',
        \   'hostname': '',
        \   'port': '',
        \   'pathname': '',
        \   'search': '',
        \   'searchParams': {},
        \   'hash': '',
        \ }

  " Get the protocol
  let l:match_results = get(matchstrlist([a:data], '\v(http:)'), 0, {})
  if get(l:match_results, 'idx', -1) == -1 || get(l:match_results, 'byteidx', -1) == -1
    throw 'ProompterError failed to parse protocol from data'
  endif
  let l:index += len(l:match_results.text)
  let l:result.protocol = l:match_results.text[0:-2]

  " Get the hostname
  let l:match_results = get(matchstrlist([a:data[l:index:]], '\v(\w+)(\.\w+)*'), 0, {})
  if get(l:match_results, 'idx', -1) == -1 || get(l:match_results, 'byteidx', -1) == -1
    throw 'ProompterError failed to parse hostname from data'
  endif
  let l:index += len(l:match_results.text)
  let l:result.hostname = l:match_results.text

  " Get the port
  let l:match_results = get(matchstrlist([a:data[l:index:]], '\v(:\d+)'), 0, {})
  if get(l:match_results, 'idx', -1) != -1 || get(l:match_results, 'byteidx', -1) != -1
    let l:index += len(l:match_results.text)
    let l:result.port = l:match_results.text[1:]
    let l:result.host = l:result.hostname . ':'. l:result.port
  else
    let l:result.host = l:result.hostname
  endif

  " Get the pathname, or keep default empty string
  let l:match_results = get(matchstrlist([a:data[l:index:]], '\v(/\w+)+'), 0, {})
  if get(l:match_results, 'idx', -1) != -1 || get(l:match_results, 'byteidx', -1) != -1
    let l:index += len(l:match_results.text)
    let l:result['pathname'] = l:match_results.text
  endif

  " Get the search, or keep default empty dictionary?
  let l:match_results = get(matchstrlist([a:data[l:index:]], '\v\?(\w+\=\w+)(\&\w+\=\w+)*'), 0, {})
  if get(l:match_results, 'idx', -1) != -1 || get(l:match_results, 'byteidx', -1) != -1
    let l:index += len(l:match_results.text)
    let l:result.search = l:match_results.text
    for l:entry in split(l:match_results.text[1:], '&')
      let l:key = split(l:entry, '=')[0]
      let l:value = split(l:entry, '=')[1]
      let l:result.searchParams[l:key] = l:value
    endfor
  endif

  let l:result.href = a:data
  let l:result.origin = l:result.protocol . '://' . l:result.host

  ""
  " TODO:
  " username: '',
  " password: '',

  return l:result
endfunction

""
" Return |string| from |dictionary| of URL components
"
" Parameter:~
" - {data} |dictionary| to parse into URL
"
" TODO:~
" - Maybe enable user/pass auth via -> https://serverfault.com/questions/371907/can-you-pass-user-pass-for-http-basic-authentication-in-url-parameters
"
" - Maybe investigate if "hash" is before or after search parameters
function! proompter#url#ToString(data) abort
  " echow 'a:data ->' a:data
  let l:result = a:data.origin

  let l:ordered_keys = [
        \   'pathname',
        \   'search',
        \ ]

  for l:entry in l:ordered_keys
    let l:result .= get(a:data, l:entry, '')
  endfor

  return l:result
endfunction


" vim: expandtab
