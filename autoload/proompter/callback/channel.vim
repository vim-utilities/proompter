#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
" Handle completely resolved HTTP response from channel proxied API
"
" Parameter: {string} channel_response - Status reported by Vim, eg. 'channel 529 closed'
" Parameter: {string} api_response - HTTP response with the following _shape_
"
" Example: expects `api_response` similar to
"
" ```
" HTTP/1.0 200 OK
" Server: SimpleHTTP/0.6 Python/3.12.6
" Date: Fri, 20 Sep 2024 23:25:06 GMT
" Content-Type: application/json
"
" {"model":"codellama","created_at":"2024-09-20T23:25:01.01645329Z","response":"V","done":false}
" {"model":"codellama","created_at":"2024-09-20T23:25:01.177902785Z","response":"im","done":false}
" {"model":"codellama","created_at":"2024-09-20T23:25:01.341776729Z","response":" is","done":false}
" {"model":"codellama","created_at":"2024-09-20T23:25:01.506237509Z","response":" the","done":false}
" {"model":"codellama","created_at":"2024-09-20T23:25:01.670272033Z","response":" best","done":false}
" ...
" {"model":"codellama","created_at":"2024-09-20T23:25:06.675058548Z","response":"","done":true,"done_reason":"stop","context":[...],"total_duration":7833808817,"load_duration":10021098,"prompt_eval_count":31,"prompt_eval_duration":2122796000,"eval_count":35,"eval_duration":5658536000}
" ```
function! proompter#callback#channel#CompleteToHistory(channel_response, api_response, ...) abort
  let l:http_response = proompter#parse#HTTPResponse(a:api_response)

  let l:data = {
        \   'type': 'response',
        \   'value': join(map(l:http_response.body, {_index, value -> value.response}), ''),
        \ }

  call add(g:proompter_state.history, l:data)
endfunction


""
" Handle stream of HTTP responses from channel proxied API
"
" Parameter: {string} channel_response - Status reported by Vim, eg. 'channel 529 closed'
" Parameter: {string} api_response - HTTP response with the following _shape_
"
" Example: expects series of `api_response` similar to
"
" ```
" HTTP/1.0 200 OK
" Server: SimpleHTTP/0.6 Python/3.12.6
" Date: Fri, 20 Sep 2024 23:25:06 GMT
" Content-Type: application/json
"
" {"model":"codellama","created_at":"2024-09-20T23:25:01.01645329Z","response":"V","done":false}
" ```
"
" ```
" HTTP/1.0 200 OK
" Server: SimpleHTTP/0.6 Python/3.12.6
" Date: Fri, 20 Sep 2024 23:25:01 GMT
" Content-Type: application/json
"
" {"model":"codellama","created_at":"2024-09-20T23:25:01.177902785Z","response":"im","done":false}
" ```
function! proompter#callback#channel#StreamToHistory(channel_response, api_response, ...) abort
  let l:http_response = proompter#parse#HTTPResponse(a:api_response)

  let l:data = {
        \   'type': 'response',
        \   'value': join(map(l:http_response.body, {_index, value -> value.response}), ''),
        \ }

  call add(g:proompter_state.history, l:data)
endfunction

""
" Handle stream of HTTP responses from channel proxied API by appending to
" buffer history, and outputting to target split.
"
" Parameter: {dictionary} kwargs - Has the following key/value pares defined
"
"   - {string} channel_response - Status reported by Vim, eg. 'channel 529 closed'
"   - {dictionary} response_tags - With `start` and `stop` values defined to
"     help LLM focus on latest input
"   - {dictionary} out_bufnr - 'state' and `out` keys pointing to buffer
"     number callback should use for state and output.
"   - {string} api_response - HTTP response _shape_ similar to following
"     examples
"
" Example: expects series of `api_response` similar to
"
" ```
" HTTP/1.0 200 OK
" Server: SimpleHTTP/0.6 Python/3.12.6
" Date: Fri, 20 Sep 2024 23:25:06 GMT
" Content-Type: application/json
"
" {"model":"codellama","created_at":"2024-09-20T23:25:01.01645329Z","response":"V","done":false}
" ```
"
" ```
" HTTP/1.0 200 OK
" Server: SimpleHTTP/0.6 Python/3.12.6
" Date: Fri, 20 Sep 2024 23:25:01 GMT
" Content-Type: application/json
"
" {"model":"codellama","created_at":"2024-09-20T23:25:01.177902785Z","response":"im","done":false}
" ```
"
" Warning: expects buffer history to be dictionary list _shaped_ similar to
"
" ```
" [
"   {
"     "type": "prompt",
"     "value": "... Maybe a question about a technical topic...",
"   },
"   {
"     "type": "response",
"     "value": "Are your finger-tips talking to you too?",
"   }
" ]
" ```
"
" Example: configuration snippet
"
" ```vim
" let g:proompter = {
"       \   'channel': {
"       \     'options': {
"       \       'callback': { channel_response, api_response ->
"       \         proompter#callback#channel#StreamToBuffer({
"       \           'channel_response': channel_response,
"       \           'api_response': api_response,
"       \           'response_tag': 'RESPONSE',
"       \           'out_bufnr': v:null,
"       \         })
"       \       },
"       \     },
"       \   },
"       \ }
" ```
function! proompter#callback#channel#StreamToBuffer(kwargs) abort
  let l:http_response = proompter#parse#HTTPResponse(a:kwargs.api_response)
  if !len(l:http_response.body)
    " echoe 'No body in HTTP Response' l:http_response
    return
  endif

  let l:out_bufnr = get(a:kwargs, 'out_bufnr', v:null)
  if l:out_bufnr == v:null || type(l:out_bufnr) == type('')
    let l:out_bufnr = proompter#lib#GetOrMakeProomptBuffer(l:out_bufnr)
  endif

  let l:json_responses = join(map(l:http_response.body, {_index, value -> value.response}), '')

  ""
  " We may use the "type" == "new" check until the end of this function
  let l:history_entry = get(
        \   g:proompter_state.history,
        \   -1,
        \   {
        \     'type': 'new',
        \     'value': l:json_responses,
        \   }
        \ )

  if l:history_entry.type == 'response'
    let l:history_entry.value .= l:json_responses
  else
    call add(g:proompter_state.history, { 'type': 'new', 'value': l:json_responses })
  endif
  let l:history_entry = g:proompter_state.history[-1]

  if l:history_entry.type == 'new'
    let l:new_buffer_lines = [
          \   '## Response ' . strftime("%Y-%m-%d %H:%M:%S") . ' `' . g:proompter.select.model_name . '`',
          \   '',
          \   '',
          \ ]

    call appendbufline(l:out_bufnr, '$', l:new_buffer_lines)
  endif

  " TODO: maybe find a better way
  call setbufline(l:out_bufnr, '$', split(getbufline(l:out_bufnr, '$')[0] . l:json_responses, '\n', 1))

  let l:history_entry.type = 'response'
endfunction

" vim: expandtab
