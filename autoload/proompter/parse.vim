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
"     "done": v:true
"   }
" ]
" ```
function! proompter#parse#JSONLinesFromHTTPResponse(data) abort
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

""
" Return dictionary with `version`, `code`, and `text` parsed from first line
" of HTTP response, or an empty dictionary if first few characters do not
" match expectations.
function! proompter#parse#StatusFromHTTPResponse(data) abort
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
" Returns either dictionary with "headers" dictionary and "body" with list of
" dictionaries parsed from HTTP response.
"
" Consumers must check length before attempting to use data because reasons.
"
" WARN: either the proxy, or Vim, or API, or some combo are to blame for
" multi-part responses where headers and body trigger streaming callback
" twice!  First with headers, then second with headless body X-P
function! proompter#parse#HTTPResponse(data) abort
  let l:status = proompter#parse#StatusFromHTTPResponse(a:data)
  let l:headers = proompter#parse#HeadersFromHTTPResponse(a:data)
  let l:body = proompter#parse#JSONLinesFromHTTPResponse(a:data)
  return { 'status': l:status, 'headers': l:headers, 'body': l:body }
endfunction

""
" Normalize response from Ollama API endpoints
"
" Returns: dictionary with shape similar to
"
" ```
" {
"   "model": "llama3.2",
"   "created_at": "2023-08-04T08:52:19.385406455-07:00",
"   "message": {
"     "role": "assistant",
"     "content": "The",
"     "images": v:null
"   },
"   "done": v:false
" }
" ```
"
" Attribution:
"
" - https://github.com/ollama/ollama/blob/main/docs/api.md#chat-request-with-history
"
" Recognized API endpoint from `g:proompter.api.url`;
"
" - `/api/generate` returns {"response": "{string} }
"
" - `/api/chat` returns either;
"   - {"message": {"role":"assistant"}, {"content":"{string}"}, {"images":null}}
"   - {"message": {"role":"assistant"}, {"content":"{string}"}, {"images":["Base64"]}}
function! proompter#parse#MessageOrResponseFromAPI(data) abort
  let l:result = {
        \   'model': a:data.model,
        \   'created_at': a:data.created_at,
        \   'message': {
        \     'role': 'assistant',
        \     'content': get(a:data, 'response', get(get(a:data, 'message', {}), 'content', '')),
        \     'images': get(a:data, 'images', v:null),
        \   },
        \   'done': a:data.done,
        \   'done_reason': get(a:data, 'done_reason', v:null),
        \ }

  return l:result
endfunction

" vim: expandtab
