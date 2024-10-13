#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter

""
" Return dictionary with `version`, `code`, and `text` parsed from first line
" of HTTP response, or an empty dictionary if first few characters do not
" match expectations.
"
" Parameter: {string} `data`
"
" Example: HTTP response data
"
" ```
" HTTP/1.1 200 OK
" Server: SimpleHTTP/0.6 Python/3.12.6
" Date: Sat, 28 Sep 2024 23:29:00 GMT
" Content-Type: application/json
"
" { "model": "codellama", "created_at": "2024-09-28T23:29:00.299380014Z", "response": " V", "done": false }
" ```
"
" Example: resulting Vim dictionary
"
" ```
" {
"   'version': '1.1',
"   'code': '200',
"   'text': 'OK',
" }
" ```
"
" See: {tests} tests/units/autoload_proompter_http_parse_response_ExtractStatus.vader
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
  let l:status.version = split(l:status_parts[0], '/')[-1]
  let l:status.code = l:status_parts[1]
  let l:status.text = join(l:status_parts[2:], ' ')

  return l:status
endfunction

""
" Convert HTTP headers into Vim dictionary, or return empty dictionary if no
" headers are parsed from input data.
"
" Parameter: {string} `data`
"
" Example: HTTP response data
"
" ```
" HTTP/1.1 200 OK
" Server: SimpleHTTP/0.6 Python/3.12.6
" Date: Sat, 28 Sep 2024 23:29:00 GMT
" Content-Type: application/json
"
" { "model": "codellama", "created_at": "2024-09-28T23:29:00.299380014Z", "response": " V", "done": false }
" ```
"
" Example: resulting Vim dictionary
"
" ```
" {
"   'Content-Type': 'application/json',
"   'Date': 'Sat, 28 Sep 2024 23:29:00 GMT',
"   'Server': 'SimpleHTTP/0.6 Python/3.12.6',
" }
" ```
"
" See: {tests} tests/units/autoload_proompter_http_parse_response_ExtractHeaders.vader
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
" Returns dictionary list built by parsing body as JSON dictionaries
"
" Example: HTTP response from `/api/generate`
"
" ```
" HTTP/1.1 200 OK
" Server: SimpleHTTP/0.6 Python/3.12.6
" Date: Sat, 28 Sep 2024 23:29:00 GMT
" Content-Type: application/json
"
" { "model": "codellama", "created_at": "2024-09-28T23:29:00.299380014Z", "response": " {", "done": false }
" { "model": "codellama", "created_at": "2024-09-20T23:25:01.670272033Z", "response": " \"foo", "done": true }
" ```
"
" Example: resulting Vim dictionary from `/api/generate`
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
"     "done": v:true
"   }
" ]
" ```
"
" See: {tests} tests/units/autoload_proompter_http_parse_response_ExtractJSONDicts.vader
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
        call add(l:dictionary_list, json_decode(a:data[l:slice_start:l:index]))

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
