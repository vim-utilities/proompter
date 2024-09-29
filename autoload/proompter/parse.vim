#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
" Convert HTTP headers into Vim dictionary, or returns empty dictionary if no
" headers are parsed from input data.
"
" Example: HTTP response
"
" ```
" Server: SimpleHTTP/0.6 Python/3.12.6
" Date: Sat, 28 Sep 2024 23:29:00 GMT
" Content-Type: application/json
"
" {"model": "codellama", "created_at": "2024-09-28T23:29:00.299380014Z", "response": " V", "done": false}
" ```
"
" Example: resulting Vim dictionary
"
" ```
" {
"   'Content-Type': 'application/json',
"   'Date': 'Sat, 28 Sep 2024 23:29:00 GMT',
"   'Server': 'SimpleHTTP/0.6 Python/3.12.6'
" }
" ```
function! proompter#parse#HeadersFromHTTPResponse(data) abort
  let l:headers = {}

  if a:data[0] !~ '\w'
    return l:headers
  endif

  let l:pattern_headers_end = '{\|$'
  let l:index = match(a:data, l:pattern_headers_end) - 1
  if l:index == -1
    return l:headers
  endif

  let l:pattern_headers_line_seperator = '\r\n\|\n\'
  let l:lines = split(a:data[:l:index], l:pattern_headers_line_seperator)
  let l:lines = filter(l:lines, 'v:val != ""')
  if len(l:lines) == 0
    return l:headers
  endif

  let l:pattern_headers_key_value_seperator = ':\s\?'
  for l:line in l:lines
    let l:key = l:line[:match(l:line, l:pattern_headers_key_value_seperator)-1]
    let l:value = l:line[matchend(l:line, l:pattern_headers_key_value_seperator):]
    let l:headers[l:key] = l:value
  endfor
  return l:headers
endfunction

""
" Returns dictionary list built by parsing body as JSON dictionaries
"
" Example: HTTP response
"
" ```
" Server: SimpleHTTP/0.6 Python/3.12.6
" Date: Sat, 28 Sep 2024 23:29:00 GMT
" Content-Type: application/json
"
" {"model": "codellama", "created_at": "2024-09-28T23:29:00.299380014Z", "response": " {", "done": false}
" {"model": "codellama", "created_at": "2024-09-20T23:25:01.670272033Z", "response": " \"foo", "done": true}
" ```
"
" Example: resulting Vim dictionary
"
" ```
" [
"   {
"     "model": "codellama",
"     "created_at": "2024-09-28T23:29:00.299380014Z",
"     "response": " {",
"     "done": v:false
"   },
"   {
"     "model": "codellama",
"     "created_at": "2024-09-20T23:25:01.670272033Z",
"     "response": ' "foo',
"     "done": v:true}
" ]
" ```
"
" Attribution:
"
" - `l:pattern` Mixtral 8x7B gurgitated `(".*\zs\{[^}]*\}\ze")@<!(\{[^}]*\})`
function! proompter#parse#JSONLinesFromHTTPResponse(data) abort
  let l:pattern = '\v(\r\n|\n|\s)*(".*\{[^}]*\}")@<!(\{[^}]*\})(\r\n|\n|\s)*'
  let l:dictionary_list = []

  let [l:json_line, l:index_start, l:index_end] = matchstrpos(a:data, l:pattern, 0)
  while l:index_start > -1 && l:index_end > -1
    call add(l:dictionary_list, json_decode(l:json_line))
    let [l:json_line, l:index_start, l:index_end] = matchstrpos(a:data, l:pattern, l:index_end)
  endwhile
  return l:dictionary_list
endfunction

""
" Returns either dictionary with "headers" dictionary and "body" with list of
" dictionaries parsed from HTTP response.
"
" Consumers must check length before attempting to use data because reasons.
"
" WARN: either the proxy, or Vim, or API, or some combo are to blame for
" multi-part responses where headers and body trigger streaming callback
" twice!  First with headers, then second with headless body X-P
function! proompter#parse#HTTPResponse(data) abort
  let l:headers = proompter#parse#HeadersFromHTTPResponse(a:data)
  let l:body = proompter#parse#JSONLinesFromHTTPResponse(a:data)
  return { 'headers': l:headers, 'body': l:body }
endfunction

""
" Returns either dictionary with "headers" and "body" keys, or "part"
"
" WARN: either the proxy, or Vim, or API, or some combo are to blame for
" multi-part responses where headers and body trigger streaming callback
" twice!  First with headers, then second with headless body X-P
function! proompter#parse#HeaderAndBodyFromHTTPResponse(data) abort
  let l:pattern = "\n{"
  let l:index = stridx(a:data, l:pattern)
  if l:index == -1
    return { 'part': a:data }
  else
    return { 'headers': a:data[:l:index], 'body': a:data[l:index+1:] }
  endif
endfunction

" vim: expandtab
