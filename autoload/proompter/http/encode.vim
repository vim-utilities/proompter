#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
" Build HTTP request via an API similar to JavaScript Request
"
" Parameters:~
" - {url} |string| that channel proxy will facilitate connection with
" - {kwargs} |dictionary| containing `headers` dictionary and `body` that may
"   be a type of dictionary, list, number, float, or string
"
" Example: post request with JSON from Vim dictionary~ >
"   let request = proompter#http#encode#Request(a:configurations.api.url, {
"         \   'method': 'post',
"         \   'headers': {
"         \     'Host': a:configurations.channel.address,
"         \     'Content-Type': 'application/json',
"         \   },
"         \   'body': {
"         \     'hello': 'World',
"         \   },
"         \ })
" <
" Expect: carriage-return/newline separated (`\r\n`) string~ >
"   POST http://127.0.0.1:11434/api/generate HTTP/1.1
"   Host:  127.0.0.1:11435
"   Content-Type:  application/json
"   Content-Length:  17
"
"   {"hello":"World"}
" <
"
" @throws ProompterError `Unknown type for a:kwargs.body -> <type>`
"
" See: tests~
" - tests/units/autoload_proompter_http_encode_Request.vader
"
" @public
function! proompter#http#encode#Request(url, kwargs) abort
  let l:line_seperator = "\r\n"

  let l:lines = [
        \   join(
        \     [
        \       toupper(a:kwargs.method),
        \       a:url,
        \       'HTTP/' . get(a:kwargs, 'version', 1.1)
        \     ],
        \     ' '
        \   )
        \ ]

  for [l:key, l:value] in items(get(a:kwargs, 'headers', {}))
    call add(l:lines, l:key . ': ' . l:value)
  endfor

  if has_key(a:kwargs, 'body')
    let l:body = ''
    let l:type_of_body = type(a:kwargs.body)
    let l:content_type = get(get(a:kwargs, 'headers', {}), 'Content-Type', v:null)

    if l:content_type == 'application/json' && l:type_of_body == v:t_dict
      let l:body = json_encode(a:kwargs.body)
    elseif l:type_of_body == v:t_list
      for l:body_line in a:kwargs.body
        let l:body .= l:body_line
      endfor
    elseif l:type_of_body == v:t_string
          \ || l:type_of_body == v:t_number
          \ || l:type_of_body == v:t_float
      let l:body = a:kwargs.body
    else
      throw 'ProompterError Unknown type for a:kwargs.body -> ' . l:type_of_body
    endif

    call add(l:lines, 'Content-Length: ' . strlen(l:body))
    call add(l:lines, '')
    call add(l:lines, l:body)
  endif

  return join(l:lines, l:line_seperator)
endfunction

" vim: expandtab
