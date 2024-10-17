#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
" Handle completely resolved HTTP response from channel proxied API and append
" results to `state.messages`
"
" Parameters:~
" - {response} |string| HTTP response with _shape_ similar to next example
" - {configurations} |ProompterConfigurations| default `g:proompter`
" - {state} |ProompterState| default `g:proompter_state`
" - {...} |list| of currently ignored arguments
"
" Example: `response` input~ >
"   HTTP/1.0 200 OK
"   Server: SimpleHTTP/0.6 Python/3.12.6
"   Date: Fri, 20 Sep 2024 23:25:06 GMT
"   Content-Type: application/json
"
"   {"model":"codellama","created_at":"2024-09-20T23:25:01.016453290Z","response":"V","done":false}
"   {"model":"codellama","created_at":"2024-09-20T23:25:01.177902785Z","response":"im","done":false}
" <
"
" @throws ProompterError with following format when non-200 status
" >
"   ProompterError HTTP response not okay -> 419 Chill Out
" <
"
" See: tests~
" - tests/units/autoload_proompter_callback_channel_CompleteToHistory.vader
"
" @public
function! proompter#callback#channel#CompleteToHistory(response, configurations = g:proompter, state = g:proompter_state, ...) abort
  let l:http_response = proompter#http#parse#Response(a:response)
  if l:http_response.status.code < 200 || l:http_response.status.code >= 300
    throw join([
          \   'ProompterError HTTP response not okay ->',
          \   l:http_response.status.code,
          \   l:http_response.status.text,
          \ ], ' ')
  endif

  let l:entry = {
        \   'model': l:http_response.body[-1].model,
        \   'created_at': l:http_response.body[-1].created_at,
        \   'done': l:http_response.body[-1].done,
        \   'done_reason': get(l:http_response.body[-1], 'done_reason', v:null),
        \   'context': get(l:http_response.body[-1], 'context', v:null),
        \   'message': {
        \     'role': 'assistant',
        \     'content': '',
        \     'images': [],
        \     'tool_calls': [],
        \   },
        \ }

  for l:http_body_data in l:http_response.body
    let l:api_data = proompter#parse#MessageOrResponseFromAPI(l:http_body_data)

    let l:entry.message.content .= l:api_data.message.content

    if type(get(l:api_data.message, 'images', v:null)) == v:t_list
      call extend(l:entry.message.images, l:api_data.message.images)
    endif

    if type(get(l:api_data.message, 'tool_calls', v:null)) == v:t_list
      call extend(l:entry.message.tool_calls, l:api_data.message.tool_calls)
    endif
  endfor

  if len(l:entry.message.images)
    echoe 'Not yet implemented!'
  else
    let l:entry.message.images = v:null
  endif

  if len(l:entry.message.tool_calls)
    echoe 'Not yet implemented!'
  else
    let l:entry.message.tool_calls = v:null
  endif

  call add(a:state.messages, l:entry)
endfunction

""
" Handle stream of HTTP responses from channel proxied API by appending to
" `state.messages` list, if the last message is not from an assistant, and in
" either case appending the `message.content` to latest assistant response.
"
" Parameters:~
" - {response} |string| HTTP response with _shape_ similar to next examples
" - {configurations} |ProompterConfigurations| default `g:proompter`
" - {state} |ProompterState| default `g:proompter_state`
" - {...} |list| of currently ignored arguments
"
" Example: expects series of `response` similar to >
"   HTTP/1.0 200 OK
"   Server: SimpleHTTP/0.6 Python/3.12.6
"   Date: Fri, 20 Sep 2024 23:25:06 GMT
"   Content-Type: application/json
"
"   {"model":"codellama","created_at":"2024-09-20T23:25:01.01645329Z","response":"V","done":false}
" < ... And... >
"   HTTP/1.0 200 OK
"   Server: SimpleHTTP/0.6 Python/3.12.6
"   Date: Fri, 20 Sep 2024 23:25:01 GMT
"   Content-Type: application/json
"
"   {"model":"codellama","created_at":"2024-09-20T23:25:01.177902785Z","response":"im","done":false}
" <
"
" @throws ProompterError with following format when non-200 status
" >
"   ProompterError HTTP response not okay -> 419 Chill Out
" <
"
" See: tests~
" - tests/units/autoload_proompter_callback_channel_StreamToMessages.vader
"
" @public
function! proompter#callback#channel#StreamToMessages(response, configurations = g:proompter, state = g:proompter_state, ...) abort
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
        \     'images': [],
        \     'tool_calls': [],
        \   },
        \ }

  let l:http_response = proompter#http#parse#Response(a:response)
  if len(l:http_response.status) && (l:http_response.status.code < 200 || l:http_response.status.code >= 300)
    throw join([
          \   'ProompterError HTTP response not okay ->',
          \   l:http_response.status.code,
          \   l:http_response.status.text,
          \ ], ' ')
  endif

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

    if type(get(l:api_data.message, 'images', v:null)) == v:t_list
      call extend(l:entry.message.images, l:api_data.message.images)
    endif

    if type(get(l:api_data.message, 'tool_calls', v:null)) == v:t_list
      call extend(l:entry.message.tool_calls, l:api_data.message.tool_calls)
    endif
  endfor

  if len(l:entry.message.images)
    echoe 'Not yet implemented!'
  else
    let l:entry.message.images = v:null
  endif

  if len(l:entry.message.tool_calls)
    echoe 'Not yet implemented!'
  else
    let l:entry.message.tool_calls = v:null
  endif

  if l:http_response.body[-1].done
    let l:entry.created_at = l:http_response.body[-1].created_at
    let l:entry.model = l:http_response.body[-1].model
    let l:entry.done = l:http_response.body[-1].done

    ""
    " From `/api/generate` when stream is `false`
    " From `/api/chat`
    let l:entry.done_reason = get(l:http_response.body[-1], 'done_reason', v:null)

    ""
    " From `/api/generate` to keep short memory via encodings
    let l:entry.context = get(l:http_response.body[-1], 'context', v:null)
  endif

  let l:entry.message.role = 'assistant'
endfunction

""
" Handle stream of HTTP responses from channel proxied API by appending to
" buffer history, and outputting to target split.
"
" Parameters:~
" - {response} |string| HTTP response _shape_ similar to next examples
" - {configurations} |ProompterConfigurations|
" - {state} |ProompterState|
" - {buffer} |string| Named or number of buffer to create, if necessary,
"   and append responses to
" - {...} |list| of currently ignored arguments
"
" Example: expects series of `response` similar to~ >
"   HTTP/1.0 200 OK
"   Server: SimpleHTTP/0.6 Python/3.12.6
"   Date: Fri, 20 Sep 2024 23:25:06 GMT
"   Content-Type: application/json
"
"   {"model":"codellama","created_at":"2024-09-20T23:25:01.01645329Z","response":"V","done":false}
" < ... Or >
"   HTTP/1.0 200 OK
"   Server: SimpleHTTP/0.6 Python/3.12.6
"   Date: Fri, 20 Sep 2024 23:25:01 GMT
"   Content-Type: application/json
"
"   {"model":"codellama","created_at":"2024-09-20T23:25:01.177902785Z","response":"im","done":false}
" <
"
" Example: configuration snippet~ >
"   let g:proompter = {
"         \   'channel': {
"         \     'options': {
"         \       'callback': { response, configurations, state ->
"         \         proompter#callback#channel#StreamToBuffer(
"         \           response,
"         \           configurations,
"         \           state,
"         \           v:null,
"         \         )
"         \       },
"         \     },
"         \   },
"         \ }
" <
"
" @throws ProompterError with following format when non-200 status
" >
"   ProompterError HTTP response not okay -> 419 Chill Out
" <
"
" See: tests~
" - tests/units/autoload_proompter_callback_channel_StreamToBuffer.vader
"
" @public
function! proompter#callback#channel#StreamToBuffer(response, configurations, state, buffer, ...) abort
  if a:buffer == v:null || type(a:buffer) == v:t_string
    let l:buffer = proompter#buffer#MakeProomptLog(a:buffer)
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
        \     'images': [],
        \     'tool_calls': [],
        \   },
        \ }

  let l:http_response = proompter#http#parse#Response(a:response)
  if len(l:http_response.status) && (l:http_response.status.code < 200 || l:http_response.status.code >= 300)
    throw join([
          \   'ProompterError HTTP response not okay ->',
          \   l:http_response.status.code,
          \   l:http_response.status.text,
          \ ], ' ')
  endif

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

    call appendbufline(l:buffer, '$', l:new_buffer_lines)
  endif

  for l:http_body_data in l:http_response.body
    let l:api_data = proompter#parse#MessageOrResponseFromAPI(l:http_body_data)

    let l:entry.message.content .= l:api_data.message.content

    call proompter#buffer#ConcatenateWithLastLine(l:buffer, l:api_data.message.content)

    if type(get(l:api_data.message, 'images', v:null)) == v:t_list
      call extend(l:entry.message.images, l:api_data.message.images)
    endif

    if type(get(l:api_data.message, 'tool_calls', v:null)) == v:t_list
      call extend(l:entry.message.tool_calls, l:api_data.message.tool_calls)
    endif
  endfor

  if l:http_response.body[-1].done
    let l:entry.created_at = l:http_response.body[-1].created_at
    let l:entry.model = l:http_response.body[-1].model
    let l:entry.done = l:http_response.body[-1].done
    let l:entry.done_reason = get(l:http_response.body[-1], 'done_reason', v:null)
    let l:entry.context = get(l:http_response.body[-1], 'context', v:null)

    call proompter#buffer#ConcatenateWithLastLine(l:buffer, "\n\n")

    if len(l:entry.message.images)
      call proompter#callback#channel#SaveImages(-1, a:configurations, a:state)
    else
      let l:entry.message.images = v:null
    endif

    if len(l:entry.message.tool_calls)
      echoe 'Not yet implemented!'
    else
      let l:entry.message.tool_calls = v:null
    endif
  endif

  let l:entry.message.role = 'assistant'
endfunction

""
" Saves base64 encoded listed at `index` from `state.messages` and
" returns list of created file paths
"
" Parameters:~
" - {index} |number| default `-1` index of `state.messages` to get images from
" - {configurations} |ProompterConfigurations| default `g:proompter`
" - {state} |ProompterState| default `g:proompter_state`
"
" @throws ProompterError `No images at message index {index}`
"
" Warns:~
" - `ProompterWarning Failed to write image -> <path>`  when file creation
"   failed, but other paths were written
"
" TODO:~
" - add configurations to `g:proompter` for defining directory
" - maybe find out file extensions some how for output images
" - maybe add OS detection for MS-Dos style path separators
"
" See: tests~
" - tests/units/autoload_proompter_callback_channel_SaveImages.vader
"
" @public
function! proompter#callback#channel#SaveImages(index = -1, configurations = g:proompter, state = g:proompter_state) abort
  let l:entry = get(get(a:state, 'messages', []), a:index, {})
  let l:images = get(l:entry, 'images', v:null)
  if l:images == v:null
    throw 'ProompterError No images at message index ->' . a:index
  endif

  let l:paths = []
  for l:image in l:images
    let l:path = join([
          \   '/tmp/',
          \   a:configurations.select.model_name,
          \   '_',
          \   strftime("%Y-%m-%d_%H%M%S"),
          \   '.png',
          \ ], '')

    if filereadable(l:path) || filewritable(l:path)
      echow 'Image already exists at ->' l:path
      continue
    endif

    call proompter#base64#DecodeToFile(l:image, l:path)

    if filereadable(l:path) && filewritable(l:path)
      call add(l:paths, path)
    else
      echow 'ProompterWarning Failed to write image ->' l:path
    endif
  endfor

  return l:paths
endfunction

" vim: expandtab
