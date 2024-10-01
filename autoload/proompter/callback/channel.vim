#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
" Handle completely resolved HTTP response from channel proxied API and append
" results to `state.messages`
"
" Parameter: {string} api_response - HTTP response with the following _shape_
" Parameter: {define__configurations} configurations - Dictionary
" Parameter: {define__proompter_state} state - Dictionary
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
function! proompter#callback#channel#CompleteToHistory(api_response, configurations = g:proompter, state = g:proompter_state, ...) abort
  let l:http_response = proompter#parse#HTTPResponse(a:api_response)

  let l:entry = {
        \   'model': l:http_response.body[-1].model,
        \   'created_at': '',
        \   'done': l:http_response.body[-1].done,
        \   'done_reason': l:http_response.body[-1].done_reason,
        \   'message': {
        \     'role': 'assistant',
        \     'content': '',
        \     'images': v:null,
        \   },
        \ }

  for l:http_body_data in l:http_response.body
    let l:api_data = proompter#parse#MessageOrResponseFromAPI(l:http_body_data)

    let l:entry.message.content .= l:api_data.message.content

    if l:api_data.message.images != v:null
      if type(l:entry.message.images) != v:t_list
        let l:entry.message.images = []
      endif

      call extend(l:entry.message.images, l:api_data.message.images)
    endif

    if !len(l:entry.created_at)
      let l:entry.created_at = l:api_data.created_at
    endif
  endfor

  call add(a:state.messages, l:entry)
endfunction


""
" Handle stream of HTTP responses from channel proxied API by appending to
" `state.messages` list, if the last message is not from an assistant, and in
" either case appending the `message.content` to latest assistant response.
"
" Parameter: {string} api_response - HTTP response with the following _shape_
" Parameter: {define__configurations} configurations - Dictionary
" Parameter: {define__proompter_state} state - Dictionary
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
function! proompter#callback#channel#StreamToMessages(api_response, configurations = g:proompter, state = g:proompter_state, ...) abort
  ""
  " We may use the "role" == "pending" check until the end of this function
  let l:entry_fallback = {
        \   'model': a:configurations.select.model_name,
        \   'created_at': v:null,
        \   'done': v:null,
        \   'done_reason': v:null,
        \   'message': {
        \     'role': 'pending',
        \     'content': '',
        \     'images': v:null,
        \   },
        \ }

  let l:http_response = proompter#parse#HTTPResponse(a:api_response)
  if len(l:http_response.body) <= 0
    " echoe 'Skipping HTTP response with empty body'
    return
  endif

  let l:entry = get(a:state.messages, -1, l:entry_fallback)
  if l:entry.message.role != 'assistant' || a:configurations.select.model_name != l:http_response.body[0].model
    call add(a:state.messages, l:entry_fallback)
  endif
  let l:entry = a:state.messages[-1]
  let l:entry.model = l:http_response.body[0].model

  for l:http_body_data in l:http_response.body
    let l:api_data = proompter#parse#MessageOrResponseFromAPI(l:http_body_data)

    let l:entry.message.content .= l:api_data.message.content

    if l:api_data.message.images != v:null
      if type(l:entry.message.images) != v:t_list
        let l:entry.message.images = []
      endif

      call extend(l:entry.message.images, l:api_data.message.images)
    endif
  endfor

  if l:http_response.body[-1].done
    let l:entry.created_at = l:http_response.body[-1].created_at
    let l:entry.model = l:http_response.body[-1].model
    let l:entry.done = l:http_response.body[-1].done
    let l:entry.done_reason = get(l:http_response.body[-1], 'done_reason', v:null)
  endif

  let l:entry.message.role = 'assistant'
endfunction

""
" Handle stream of HTTP responses from channel proxied API by appending to
" buffer history, and outputting to target split.
"
" Parameter: {string} api_response - HTTP response _shape_ similar to following examples
" Parameter: {define__configurations} configurations - Dictionary
" Parameter: {define__proompter_state} state - Dictionary
" Parameter: {string} out_bufnr - Named or number of buffer to create, if
" necessary, and append responses to
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
" Example: configuration snippet
"
" ```vim
" let g:proompter = {
"       \   'channel': {
"       \     'options': {
"       \       'callback': { api_response, configurations, state ->
"       \         proompter#callback#channel#StreamToBuffer(
"       \           api_response,
"       \           configurations,
"       \           state,
"       \           v:null,
"       \         )
"       \       },
"       \     },
"       \   },
"       \ }
" ```
function! proompter#callback#channel#StreamToBuffer(api_response, configurations, state, out_bufnr, ...) abort
  if a:out_bufnr == v:null || type(a:out_bufnr) == v:t_string
    let l:out_bufnr = proompter#lib#GetOrMakeProomptBuffer(a:out_bufnr)
  endif

  ""
  " We may use the "role" == "pending" check until the end of this function
  let l:entry_fallback = {
        \   'model': v:null,
        \   'created_at': v:null,
        \   'done': v:null,
        \   'done_reason': v:null,
        \   'message': {
        \     'role': 'pending',
        \     'content': '',
        \     'images': v:null,
        \   },
        \ }

  let l:http_response = proompter#parse#HTTPResponse(a:api_response)
  if len(l:http_response.body) <= 0
    " echoe 'Skipping HTTP response with empty body'
    return
  endif

  let l:entry = get(a:state.messages, -1, l:entry_fallback)
  if l:entry.message.role != 'assistant' || a:configurations.select.model_name != l:http_response.body[0].model
    call add(a:state.messages, l:entry_fallback)
  endif
  let l:entry = a:state.messages[-1]
  let l:entry.model = l:http_response.body[0].model

  if l:entry.message.role == 'pending'
    let l:new_buffer_lines = [
          \   '## Response ' . strftime("%Y-%m-%d %H:%M:%S") . ' `' . a:configurations.select.model_name . '`',
          \   '',
          \   '',
          \ ]

    call appendbufline(l:out_bufnr, '$', l:new_buffer_lines)
  endif

  for l:http_body_data in l:http_response.body
    let l:api_data = proompter#parse#MessageOrResponseFromAPI(l:http_body_data)

    let l:entry.message.content .= l:api_data.message.content

    let l:buffer_last_line = get(getbufline(l:out_bufnr, '$'), 0, '')
    let l:buffer_last_line .= l:api_data.message.content
    call setbufline(l:out_bufnr, '$', split(l:buffer_last_line, '\n', 1))

    if l:api_data.message.images != v:null
      if type(l:entry.message.images) != v:t_list
        let l:entry.message.images = []
      endif

      call extend(l:entry.message.images, l:api_data.message.images)
    endif
  endfor

  if l:http_response.body[-1].done
    let l:entry.created_at = l:http_response.body[-1].created_at
    let l:entry.model = l:http_response.body[-1].model
    let l:entry.done = l:http_response.body[-1].done
    let l:entry.done_reason = get(l:http_response.body[-1], 'done_reason', v:null)
  endif

  let l:entry.message.role = 'assistant'
endfunction

" vim: expandtab
