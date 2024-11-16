#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter



""
" @dict HTTPStatus
"
" Example: HTTP Status Vim dictionary~ >
"   {
"     'version': '1.1',
"     'code': 200,
"     'text': 'OK',
"   }
" <
"
" {version} is a |string| because we cannot trust that a server/service may
" report a non-float compatible number
"
" {code} |number| Generally 200 to 299 are okay, less than 200 are for
" information, 300 to 399 are redirection, and anything higher are errors.
"
" {text} |string|
"
" See: MDN documentation for details about HTTP Status codes and data~
" - https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
" - https://developer.mozilla.org/en-US/docs/Web/API/Response/statusText

""
" Parses first line of input {data} |string| and returns either an empty
" dictionary, if it cannot parse input, or a |HTTPStatus| dictionary with
" `version`, `code`, and `text` keys/value pares.
"
" @public
function! proompter#http#parse#response#ExtractStatus(data) abort
  let l:status = {}

  if a:data[0:4] != 'HTTP/'
    return l:status
  endif

  let l:pattern_line_seperator = '\r\n\|\n'
  let l:match_results = get(matchstrlist([a:data], l:pattern_line_seperator), 0, {})
  if get(l:match_results, 'idx', -1) == -1 || get(l:match_results, 'byteidx', -1) == -1
    return l:status
  endif

  let l:first_line = a:data[:l:match_results.byteidx-1]
  let l:status_parts = split(l:first_line, ' ')
  let l:code = str2nr(l:status_parts[1])
  if string(l:code) == l:status_parts[1]
    let l:status.code = l:code
  else
    return l:status
  endif

  let l:status.version = split(l:status_parts[0], '/')[-1]
  let l:status.text = join(l:status_parts[2:], ' ')

  return l:status
endfunction

""
" @dict HTTPHeaders
"
" {string} `key` Whatever string was read between first colon (`:`) and start
" of each line
"
" {string} `value` Everything after first colon (`:`) and end of each line
"
" Example: HTTP response data~ >
"   HTTP/1.1 200 OK
"   Server: SimpleHTTP/0.6 Python/3.12.6
"   Date: Sat, 28 Sep 2024 23:29:00 GMT
"   Content-Type: application/json
"
"   {"key":"value"}
" <
"
" Example: HTTP Headers Vim dictionary~ >
"   {
"     'Content-Type': 'application/json',
"     'Date': 'Sat, 28 Sep 2024 23:29:00 GMT',
"     'Server': 'SimpleHTTP/0.6 Python/3.12.6',
"   }
" <

""
" Parses lines of input {data} |string| until first blank line ("\r\n\r\n")
" and returns either an empty dictionary, if it cannot parse input, or a
" |HTTPHeaders| dictionary.
"
" See: tests~
" - tests/units/autoload_proompter_http_parse_response_ExtractHeaders.vader
"
" @public
function! proompter#http#parse#response#ExtractHeaders(data) abort
  let l:headers = {}

  if a:data[0] !~ '\w'
    return l:headers
  endif

  let l:pattern_headers_end = '{\|$'
  let l:index = match(a:data, l:pattern_headers_end) - 1
  if l:index == -1
    return l:headers
  endif

  let l:pattern_headers_line_seperator = '\r\n\|\n'
  let l:lines = split(a:data[:l:index], l:pattern_headers_line_seperator)
  let l:lines = filter(l:lines, 'v:val != ""')
  if len(l:lines) == 0
    return l:headers
  endif

  let l:pattern_headers_key_value_seperator = ':\s\?'
  for l:line in l:lines
    let l:index = match(l:line, l:pattern_headers_key_value_seperator)
    if l:index == -1
      continue
    endif

    let l:key = l:line[:l:index-1]
    let l:value = l:line[l:index+2:]
    if len(l:key) && len(l:value)
      let l:headers[l:key] = l:value
    endif
  endfor

  return l:headers
endfunction

""
" Returns dictionary list built by parsing body as JSON dictionaries from
" input |string| {data}.
"
" Example: HTTP response from `/api/generate`~ >
"   HTTP/1.1 200 OK
"   Server: SimpleHTTP/0.6 Python/3.12.6
"   Date: Sat, 28 Sep 2024 23:29:00 GMT
"   Content-Type: application/json
"
"   {"model":"codellama","created_at":"2024-09-28T23:29:00.299380014Z","response":"{","done":false}
"   {"model":"codellama","created_at":"2024-09-20T23:25:01.670272033Z","response":"\"foo","done":true}
" <
"
" Example: resulting Vim dictionary from `/api/generate`~ >
"   [
"     {
"       "model": "codellama",
"       "created_at": "2024-09-28T23:29:00.299380014Z",
"       "response": "{",
"       "done": v:false
"     },
"     {
"       "model": "codellama",
"       "created_at": "2024-09-20T23:25:01.670272033Z",
"       "response": '"foo',
"       "done": v:true
"     }
"   ]
" <
"
" See: documentation~
" - |APIResponseChat|
" - |APIResponseGenerate|
"
" See: tests~
" - tests/units/autoload_proompter_http_parse_response_ExtractJSONDicts.vader
"
" @public
function! proompter#http#parse#response#ExtractJSONDicts(data) abort
  let l:dictionary_list = []

  let l:index = 0
  let l:slice_start = 0
  let l:inside_string = v:false
  let l:escape_count = 0
  let l:curly_depth = 0
  while l:index < len(a:data)
    let l:character = a:data[l:index]

    if l:inside_string
      if l:character == '\'
        let l:escape_count += 1
      else
        if l:character == '"'
          if l:escape_count % 2 == 0
            let l:inside_string = v:false
          else
            let l:inside_string = v:true
          endif
        endif

        let l:escape_count = 0
      endif
    elseif l:character == '"'
      let l:inside_string = v:true
    elseif l:character == '{'
      let l:curly_depth += 1
    elseif l:character == '}'
      let l:curly_depth -= 1
      if l:curly_depth == 0
        call add(l:dictionary_list, proompter#json#Parse(a:data[l:slice_start:l:index]))

        let l:slice_start = l:index + 1
        let l:inside_string = v:false
        let l:escape_count = 0
      endif
    elseif l:curly_depth == 0
      let l:slice_start = l:index + 1
    endif

    let l:index += 1
  endwhile

  return l:dictionary_list
endfunction

" vim: expandtab
