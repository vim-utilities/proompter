#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
" Parameters:~
" - {value} |string| what will eventually be sent to LLM
" - {configurations} |ProompterConfigurations| default `g:proompter`
" - {state} |ProompterState| default `g:proompter_state`
"
" Entry added to `a:state.messages` will have a format similar to >
"   {
"     "model": "codellama",
"     "created_at": "2024-09-20T23:25:06.675058548Z",
"     "message": {
"       "role": "user",
"       "content": "Tell me Vim is the best text editor.",
"       "image": v:null,
"     }
"   }
" <
"
" ...  if an input callback function can be found then `message.content` in
" above example will be overwritten by content values of that function
" separated by two newlines.
"
" Example: call~ >
"   let message = 'Tell me in one sentence why Bash is the best'
"   call proompter#SendPromptToGenerate(message)
" <
"
" @throws ProompterError `Non-string value`
"
" Note: if `g:proompter.models['model_name'].prompt_callbacks` is defined then
"       resulting prompt sent to LLM is built by `prompt_callbacks.post`
"       callback if available, else the following are appended in order;
"       `preamble`, `prompt`, and `input`
"
"       else `g:proompter.models['model_name'].prompt_callbacks` is undefined
"       `g:proompter.models['model_name'].data.prompt` is prepended to `value`
"       before being sent to LLM at `g:proompter.api.url` via channel proxy
"
" Dev: without the slicing output of `shellescape` the append/prepend-ed
"      single-quotes which ain't gonna be good within a larger JSON object
"
" See: documentation~
" - |strftime()|
" - |reltime()|
"
" TODO: preform feature detection for `strftime` and `reltime`
"
" @public
function! proompter#SendPromptToChat(value, configurations = g:proompter, state = g:proompter_state) abort
  if type(a:value) != v:t_string
    throw 'ProompterError Non-string value'
  endif

  let l:model_name = a:configurations.select.model_name
  let l:model = deepcopy(get(a:configurations.models, l:model_name, {
        \   'prompt_callbacks': {
        \     'chat': {},
        \     'generate': {},
        \   },
        \   'data': {
        \     'raw': v:false,
        \     'stream': v:true,
        \   },
        \ }))

  let l:model.data.model = l:model_name

  let l:callbacks = proompter#lib#DictMerge(
        \   get(get(get(a:configurations, 'api', {}), 'prompt_callbacks', {}), 'chat', {}),
        \   get(get(l:model, 'prompt_callbacks', {}), 'chat', {}),
        \ )

  let l:entry = {
        \   'model': a:configurations.select.model_name,
        \   'created_at': strftime('%FT%T.') . reltime()[1] . 'Z',
        \   'message': {
        \     'role': 'user',
        \     'content': a:value,
        \     'images': v:null,
        \   },
        \ }

  let l:messages = get(l:model.data, 'messages', [])
  if type(get(l:model, 'prompt_callbacks')) == v:t_dict
    let l:callbacks_results = {
          \   'preamble': [],
          \   'context': [],
          \   'input': [],
          \ }

    if type(get(l:callbacks, 'preamble')) == v:t_func
      call extend(l:callbacks_results.preamble, l:callbacks.preamble(a:configurations, a:state))
    endif

    if type(get(l:callbacks, 'context')) == v:t_func
      call extend(l:callbacks_results.context, l:callbacks.context(a:configurations, a:state))
    endif

    if type(get(l:callbacks, 'input')) == v:t_func
      let l:input_result = l:callbacks.input(a:value, a:configurations, a:state)
      call extend(l:callbacks_results.input, l:input_result)

      let l:entry.message.content = join(map(l:input_result, { _index, message ->
            \   message.content
            \ }), "\n\n")
    endif

    if type(get(l:callbacks, 'post')) == v:t_func
      call extend(l:messages, l:callbacks.post(l:callbacks_results, a:configurations, a:state))
    else
      call extend(l:messages, l:callbacks_results.preamble)
      call extend(l:messages, l:callbacks_results.context)
      call extend(l:messages, l:callbacks_results.input)
    endif

    if type(get(l:callbacks, 'images')) == v:t_func
      let l:entry.message.images = l:callbacks.images(a:value, a:configurations, a:state)

      let l:last_message = l:messages[-1]
      if type(get(l:last_message, 'images', v:null)) == v:t_none
        let l:last_message.images = l:entry.message.images
      endif
    endif
  else
    call add(l:messages, { 'role': 'user', 'content': a:value })
  endif
  let l:model.data.messages = l:messages

  call add(a:state.messages, l:entry)

  let l:post_payload = proompter#http#encode#Request(a:configurations.api.url, {
        \   'method': 'post',
        \   'headers': {
        \     'Host': a:configurations.channel.address,
        \     'Content-Type': 'application/json',
        \   },
        \   'body': l:model.data,
        \ })

  let l:channel = proompter#channel#GetOrSetOpen(a:configurations, a:state)

  call ch_sendraw(l:channel, l:post_payload)
endfunction

""
" Parameters:~
" - {value} |string| what will eventually be sent to LLM
" - {configurations} |ProompterConfigurations| default `g:proompter`
" - {state} |ProompterState| default `g:proompter_state`
"
" Example: call~ >
"   let message = 'Tell me in one sentence why Bash is the best'
"   call proompter#SendPromptToGenerate(message)
" <
"
" @throws ProompterError `Non-string value`
"
" Note: if `g:proompter.models['model_name'].prompt_callbacks` is defined then
"       resulting prompt sent to LLM is built by `prompt_callbacks.post`
"       callback if available, else the following are appended in order;
"       `preamble`, `prompt`, and `input`
"
"       else `g:proompter.models['model_name'].prompt_callbacks` is undefined
"       `g:proompter.models['model_name'].data.prompt` is prepended to `value`
"       before being sent to LLM at `g:proompter.api.url` via channel proxy
"
" Dev: without the slicing output of `shellescape` the append/prepend-ed
"      single-quotes which ain't gonna be good within a larger JSON object
"
" @public
function! proompter#SendPromptToGenerate(value, configurations = g:proompter, state = g:proompter_state) abort
  if type(a:value) != v:t_string
    throw 'ProompterError Non-string value'
  endif

  let l:model_name = a:configurations.select.model_name
  let l:model = deepcopy(get(a:configurations.models, l:model_name, {
        \   'prompt_callbacks': {
        \     'chat': {},
        \     'generate': {},
        \   },
        \   'data': {
        \     'raw': v:false,
        \     'stream': v:true,
        \   },
        \ }))

  let l:model.data.model = l:model_name

  let l:prompt = get(l:model.data, 'prompt', '')

  let l:callbacks = proompter#lib#DictMerge(
        \   get(get(get(a:configurations, 'api', {}), 'prompt_callbacks', {}), 'generate', {}),
        \   get(get(l:model, 'prompt_callbacks', {}), 'generate', {}),
        \ )

  let l:entry = {
        \   'model': a:configurations.select.model_name,
        \   'created_at': strftime('%FT%T.') . reltime()[1] . 'Z',
        \   'message': {
        \     'role': 'user',
        \     'content': a:value,
        \     'images': v:null,
        \   },
        \ }

  ""
  " Next is all about setting `l:model.data.prompt`
  if type(get(l:model, 'prompt_callbacks')) == v:t_dict
    let l:callbacks_results = {
          \   'preamble': '',
          \   'context': '',
          \   'input': '',
          \ }

    if type(get(l:callbacks, 'preamble')) == v:t_func
      let l:callbacks_results.preamble .= l:callbacks.preamble(a:configurations, a:state)
    endif

    if type(get(l:callbacks, 'context')) == v:t_func
      let l:callbacks_results.context .= l:callbacks.context(a:configurations, a:state)
    endif

    if type(get(l:callbacks, 'input')) == v:t_func
      let l:callbacks_results.input .= l:callbacks.input(a:value, a:configurations, a:state)
    endif

    if type(get(l:callbacks, 'images')) == v:t_func
      let l:entry.messages.images = l:callbacks.images(a:value, a:configurations, a:state)
      let l:model.data.images = l:entry.messages.images
    endif

    if type(get(l:callbacks, 'post')) == v:t_func
      let l:prompt .= l:callbacks.post(l:callbacks_results, a:configurations, a:state)
    else
      let l:prompt .= l:callbacks_results.preamble
      let l:prompt .= l:callbacks_results.context
      let l:prompt .= l:callbacks_results.input
    endif
  else
    let l:prompt .= a:value
  endif
  let l:model.data.prompt = l:prompt

  call add(a:state.messages, l:entry)

  let l:post_payload = proompter#http#encode#Request(a:configurations.api.url, {
        \   'method': 'post',
        \   'headers': {
        \     'Host': a:configurations.channel.address,
        \     'Content-Type': 'application/json',
        \   },
        \   'body': l:model.data,
        \ })

  let l:channel = proompter#channel#GetOrSetOpen(a:configurations, a:state)

  call ch_sendraw(l:channel, l:post_payload)
endfunction

""
" Parameters:~
" - {value} |string| what will eventually be sent to LLM
" - {configurations} |ProompterConfigurations| default `g:proompter`
" - {state} |ProompterState| default `g:proompter_state`
"
" Example: call~ >
"   let message = 'Tell me in one sentence why Bash is the best'
"   call proompter#SendPrompt(message)
" <
"
" @throws ProompterError with message similar to
" >
"   Nothing implemented for API endpoint in  -> [url]
" <
"
" Note: if `g:proompter.models['model_name'].prompt_callbacks` is defined then
"       resulting prompt sent to LLM is built by `prompt_callbacks.post`
"       callback if available, else the following are appended in order;
"       `preamble`, `prompt`, and `input`
"
"       else `g:proompter.models['model_name'].prompt_callbacks` is undefined
"       `g:proompter.models['model_name'].data.prompt` is prepended to `value`
"       before being sent to LLM at `g:proompter.api.url` via channel proxy
"
" Dev: without the slicing output of `shellescape` the append/prepend-ed
"      single-quotes which ain't gonna be good within a larger JSON object
"
" @public
function! proompter#SendPrompt(value, configurations = g:proompter, state = g:proompter_state) abort
  let l:api_endpoint = split(a:configurations.api.url, '/')[-1]
  let l:api_endpoint = split(l:api_endpoint, '?')[0]
  if l:api_endpoint == 'chat'
    return proompter#SendPromptToChat(a:value, a:configurations, a:state)
  elseif l:api_endpoint == 'generate'
    return proompter#SendPromptToGenerate(a:value, a:configurations, a:state)
  endif
  throw 'ProompterError Nothing implemented for API endpoint in  ->' . a:configurations.api.url
endfunction

""
" Send range or visually selected text to LLM
"
" Parameters:~
" - {prefix} |string| default `""` what will eventually be sent to LLM
" - {configurations} |ProompterConfigurations| default `g:proompter`
" - {state} |ProompterState| default `g:proompter_state`
"
" Note: if `&filetype` is recognized member of `g:markdown_fenced_languages`
" then selected text will be fenced with a name triple backticks.
"
" Example: call~ >
"   :'<,'>call proompter#SendHighlightedText()
"
"   :69,420call proompter#SendHighlightedText()
"
"   :call proompter#SendHighlightedText('What does this line do?')
" <
"
" See: documentation~
" - |optional-function-argument|
" - |g:markdown_fenced_languages|
"
" @public
function! proompter#SendHighlightedText(prefix = '', configurations = g:proompter, state = g:proompter_state) abort range
  let l:selection = getline(a:firstline, a:lastline)

  if len(&filetype) && exists('g:markdown_fenced_languages')
    let l:pattern = '\v<' . &filetype . '>'
    if indexof(g:markdown_fenced_languages, { _index, entry -> entry =~ l:pattern }) >= 0
      let l:selection = ['```' . &filetype] + l:selection + ['```']
    endif
  endif

  if len(a:prefix)
    let l:selection = [a:prefix, ''] + l:selection
  endif

  let l:value = join(l:selection, "\n")
  call proompter#SendPrompt(l:value, a:configurations, a:state)
endfunction

""
" Wrapper for `ch_close` for whatever channel is in `a:state.channel`
function! proompter#Cancel(state = g:proompter_state, configurations = g:proompter) abort
  call ch_close(a:state.channel)
endfunction

""
" Attempt to load a model into memory
"
" @throws ProompterError `Unknown endpoing in -> a:configurations.api.url`
"
" See: links~
" - https://github.com/ollama/ollama/blob/main/docs/api.md#load-a-model
"
" @public
function! proompter#Load(configurations = g:proompter, state = g:proompter_state) abort
  let l:model_data = { "model": a:configurations.select.model_name }

  let l:api_endpoint = split(a:configurations.api.url, '/')[-1]
  let l:api_endpoint = split(l:api_endpoint, '?')[0]
  if l:api_endpoint == 'chat'
    return proompter#SendPromptToChat('', a:configurations, a:state)
  elseif l:api_endpoint == 'generate'
    return proompter#SendPromptToGenerate('', a:configurations, a:state)
  endif

  let l:post_payload = proompter#http#encode#Request(a:configurations.api.url, {
        \   'method': 'post',
        \   'headers': {
        \     'Host': a:configurations.channel.address,
        \     'Content-Type': 'application/json',
        \   },
        \   'body': l:model.data,
        \ })

  let l:channel = proompter#channel#GetOrSetOpen(a:configurations, a:state)

  call ch_sendraw(l:channel, l:post_payload)
endfunction

""
" Tell API it is okay to release memory for a model
"
" @throws ProompterError `Unknown endpoing in -> a:configurations.select.completion_endpoint`
"
" See: links~
" - https://github.com/ollama/ollama/blob/main/docs/api.md#load-a-model
"
" @public
function! proompter#Unload(configurations = g:proompter, state = g:proompter_state) abort
  let l:model_data = {
        \   "model": a:configurations.select.model_name,
        \   "keep_alive": 0,
        \ }

  let l:api_endpoint = split(a:configurations.api.url, '/')[-1]
  let l:api_endpoint = split(l:api_endpoint, '?')[0]
  if l:api_endpoint == 'chat'
    return proompter#SendPromptToChat('', a:configurations, a:state)
  elseif l:api_endpoint == 'generate'
    return proompter#SendPromptToGenerate('', a:configurations, a:state)
  endif

  let l:post_payload = proompter#http#encode#Request(a:configurations.api.url, {
        \   'method': 'post',
        \   'headers': {
        \     'Host': a:configurations.channel.address,
        \     'Content-Type': 'application/json',
        \   },
        \   'body': l:model.data,
        \ })

  let l:channel = proompter#channel#GetOrSetOpen(a:configurations, a:state)

  call ch_sendraw(l:channel, l:post_payload)
endfunction

" vim: expandtab
