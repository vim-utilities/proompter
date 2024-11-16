#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter
"
" These are indented to be used when `g:proompter.select.completion_endpoint`
" is `chat`



""
" Return start of prompt with content similar to following >
"   [
"     {
"       "role": "system",
"       "content": "You an expert with javascript...",
"     },
"   ]
" <
"
" Parameter:~
" - {kwargs} |dictionary| with the following key/value pares defined;
"   - `filetype` |string| of what file type is operated on, if not defined
"     will attempt to default with `&filetype` and if that is undefined return
"     an empty list.
"   - `configurations` |ProompterConfigurations| ignored for now
"   - `state` |ProompterState| ignored for now
"
" Example: configuration snippet~ >
"   let g:proompter = {
"         \   "select": {
"         \     "model_name": "codellama",
"         \     "completion_endpoint": "chat",
"         \   },
"         \   "api": {
"         \     "url": "http://127.0.0.1:11434",
"         \     "prompt_callbacks": {
"         \       "chat": {
"         \         "preamble": { _configurations, _state ->
"         \           proompter#callback#prompt#chat#Preamble({
"         \             "filetype": "javascript",
"         \             "configurations": _configurations,
"         \             "state": _state,
"         \           })
"         \         },
"         \       },
"         \     },
"         \   },
"         \ }
" <
"
" See: tests~
" - tests/units/autoload_proompter_callback_prompt_chat_Preamble.vader
"
" @public
function! proompter#callback#prompt#chat#Preamble(kwargs) abort
  let l:messages = []

  let l:filetype = get(a:kwargs, 'filetype', &filetype)
  if !len(l:filetype) || l:filetype == 'markdown'
    return l:messages
  endif

  return extend(l:messages, [{
        \   'role': 'system',
        \   'content': 'You are an expert with ' . l:filetype
        \ }])
endfunction

""
" Return no more than `a:kwargs.context_size` last past prompt/response-s >
"   [
"     {
"       "role": "user",
"       "content": "Tell me in one sentence why Vim is the best text editor.",
"     },
"     {
"       "role": "assistant",
"       "content": "Vim is the best!",
"     },
"   ]
" <
"
" Parameter:~
" - {kwargs} |dictionary| with the following key/value pares defined;
"   - `context_size` |number| of max prompt/response that are re-shared
"   - `configurations` |ProompterConfigurations| ignored for now
"   - `state` |ProompterState|
"
" Warning: expects `a:kwargs.state.messages` to be dictionary list _shaped_
" minimally similar to; >
"   [
"     {
"       "message": {
"         "role": "user",
"         "content": "... Maybe a question about a technical topic...",
"       },
"     },
"     {
"       "message": {
"         "role": "assistant",
"         "content": "Are your finger-tips talking to you too?",
"       },
"     },
"   ]
" <
"
" Example: configuration snippet~ >
"   let g:proompter = {
"         \   "select": {
"         \     "model_name": "codellama",
"         \     "completion_endpoint": "chat",
"         \   },
"         \   "api": {
"         \     "url": "http://127.0.0.1:11434",
"         \     "prompt_callbacks": {
"         \       "chat": {
"         \         "context": { _configurations, state ->
"         \           proompter#callback#prompt#chat#Context({
"         \             "context_size": 5,
"         \             "configurations": _configurations,
"         \             "state": state,
"         \           })
"         \         },
"         \       },
"         \     },
"         \   },
"         \ }
" <
"
" See: tests~
" - tests/units/autoload_proompter_callback_prompt_chat_Context.vader
"
" @public
function! proompter#callback#prompt#chat#Context(kwargs) abort
  let l:context_size = get(a:kwargs, 'context_size', 0)
  let l:index_start = max([len(a:kwargs.state.messages) - l:context_size, 0])
  let l:messages = a:kwargs.state.messages[l:index_start:]
  if !len(l:messages)
    return []
  endif

  return mapnew(l:messages, { _index, entry ->
        \   {
        \     'role': entry.message.role,
        \     'content': entry.message.content,
        \     'images': get(entry.message, 'images', v:null),
        \   }
        \ })
endfunction

""
" Returns a dictionary list formatted from `input` similar to; >
"   [
"     {
"       "role": "user",
"       "content": "Tell me in one sentence Vim is the best.",
"     },
"   ]
" <
"
" Parameters:~
" - {input} |string| text to prompt LLM with
" - {configurations} |ProompterConfigurations| ignored for now
" - {state} |ProompterState| ignored for now
" - {...} |list| of currently ignored arguments
"
" Example: configuration snippet~ >
"   let g:proompter = {
"         \   "select": {
"         \     "model_name": "codellama",
"         \     "completion_endpoint": "chat",
"         \   },
"         \   "api": {
"         \     "url": "http://127.0.0.1:11434",
"         \     "prompt_callbacks": {
"         \       "chat": {
"         \         "input": function("proompter#callback#prompt#chat#Input"),
"         \       },
"         \     },
"         \   },
"         \ }
" <
"
" See: tests~
" - tests/units/autoload_proompter_callback_prompt_chat_Input.vader
"
" @public
function! proompter#callback#prompt#chat#Input(input, _configurations, _state, ...) abort
  return [{ 'role': 'user', 'content': a:input }]
endfunction

""
" Merge together outputs from other prompt callback functions and write to
" defined output buffer before returning list of messages to send to LLM
"
" Parameter: {kwargs} |dictionary| with the following key/value pares defined;
" - `data` |dictionary| with `preamble`, `context`, and `input` keys pointing
"   to string values.
" - `out_bufnr` buffer |number| or |string| name used for output, if |v:null|
"   one will be created automatically via |proompter#buffer#MakeProomptLog|
"   with the name "proompt-log.md", or you may set a string value to customize
"   the buffer name.
" - `configurations` |ProompterConfigurations| ignored for now
" - `state` |ProompterState| ignored for now
"
" Example: configuration snippet~ >
"   let g:proompter = {
"         \   "select": {
"         \     "model_name": "codellama",
"         \     "completion_endpoint": "chat",
"         \   },
"         \   "api": {
"         \     "url": "http://127.0.0.1:11434",
"         \     "prompt_callbacks": {
"         \       "chat": {
"         \         "post": {
"         \            prompt_callbacks_data, _configurations, _state ->
"         \             proompter#callback#prompt#chat#Post({
"         \               "data": prompt_callbacks_data,
"         \               "out_bufnr": v:null,
"         \               "configurations": _configurations,
"         \               "state": _state,
"         \           })
"         \         },
"         \       },
"         \     },
"         \   },
"         \ }
" <
"
" Example: `out_bufnr` content~ >
"   ## Prompt 2024-10-04 20:06:09
"
"
"   Write documentation for the following function using JS-Doc comment syntax
"
"   ```javascript
"   function greet(who = 'World') {
"     return `Hello ${who}!`;
"   }
"   ```
" <
"
" Example: `l:messages` returned data~ >
"   [
"     {
"       "role": "system",
"       "content": "You an expert with and delight in solving problems!",
"     },
"     {
"       "role": "user",
"       "content": "Write documentation for the following...",
"     },
"   ]
" <
"
" See: tests~
" - tests/units/autoload_proompter_callback_prompt_chat_Post.vader
"
" @public
function! proompter#callback#prompt#chat#Post(kwargs) abort
  let l:out_bufnr = get(a:kwargs, 'out_bufnr', v:null)
  if l:out_bufnr == v:null || type(l:out_bufnr) == v:t_string
    let l:out_bufnr = proompter#buffer#MakeProomptLog(l:out_bufnr)
  endif

  let l:prompt_heading_lines = extend([
        \   '## Prompt ' . strftime("%Y-%m-%d %H:%M:%S"),
        \   '',
        \   '',
        \ ], mapnew(a:kwargs.data.input, { _index, message -> message.content }))

  if getbufinfo(l:out_bufnr)[0].linecount > 1
    let l:prompt_heading_lines = extend([''], l:prompt_heading_lines)
  endif
  call extend(l:prompt_heading_lines, ['', ''])

  call proompter#buffer#ConcatenateWithLastLine(
        \   l:out_bufnr,
        \   join(l:prompt_heading_lines, "\n")
        \ )

  let l:messages = []
  let l:keys = [ 'preamble', 'context', 'input' ]
  for l:key in l:keys
    call extend(l:messages, get(a:kwargs.data, l:key, []))
  endfor
  return l:messages
endfunction

" vim: expandtab
