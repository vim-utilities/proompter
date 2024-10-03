#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
" Parameter: {string} value - What will eventually be sent to LLM
" Parameter: {define__configurations} configurations
" Parameter: {define__proompter_state} state - Dictionary
"
" Example:
"
" ```vim
" :call proompter#SendPromptToGenerate('Tell me in one sentence why Bash is the best scripting language')
" ```
"
" Throw: when `value` is empty or zero length
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
function! proompter#SendPromptToChat(value, configurations = g:proompter, state = g:proompter_state) abort
  if len(a:value) == 0
    throw 'Proompter: empty input value'
  endif

  let l:model_name = a:configurations.select.model_name
  let l:model = deepcopy(a:configurations.models[l:model_name])
  let l:model.data.model = l:model_name

  let l:messages = get(l:model.data, 'messages', [])
  if type(get(l:model, 'prompt_callbacks')) == v:t_dict
    let l:callbacks_results = {
          \   'preamble': [],
          \   'context': [],
          \   'input': [],
          \ }

    if type(get(l:model.prompt_callbacks, 'preamble')) == v:t_func
      call extend(l:callbacks_results.preamble, l:model.prompt_callbacks.preamble(a:configurations, a:state))
    endif

    if type(get(l:model.prompt_callbacks, 'context')) == v:t_func
      call extend(l:callbacks_results.context, l:model.context_callbacks.context(a:configurations, a:state))
    endif

    if type(get(l:model.prompt_callbacks, 'input')) == v:t_func
      call extend(l:callbacks_results.input, l:model.prompt_callbacks.input(a:value, a:configurations, a:state))
    endif

    if type(get(l:model.prompt_callbacks, 'post')) == v:t_func
      call extend(l:messages, l:model.prompt_callbacks.post(l:callbacks_results, a:configurations, a:state))
    else
      call extend(l:messages, l:callbacks_results.preamble)
      call extend(l:messages, l:callbacks_results.context)
      call extend(l:messages, l:callbacks_results.input)
    endif
  else
    call add(l:messages, { 'role': 'user', 'content': a:value })
  endif
  let l:model.data.messages = l:messages

  call add(a:state.messages, {
        \   'message': {
        \     'role': 'user',
        \     'content':  a:value
        \   },
        \ })

  let l:post_payload = proompter#format#HTTPPost(l:model.data, a:configurations)

  let l:channel = proompter#channel#GetOrSetOpen(a:configurations, a:state)

  call ch_sendraw(l:channel, l:post_payload)
endfunction

""
" Parameter: {string} value - What will eventually be sent to LLM
" Parameter: {define__configurations} configurations
" Parameter: {define__proompter_state} state - Dictionary
"
" Example:
"
" ```vim
" :call proompter#SendPromptToGenerate('Tell me in one sentence why Bash is the best scripting language')
" ```
"
" Throw: when `value` is empty or zero length
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
function! proompter#SendPromptToGenerate(value, configurations = g:proompter, state = g:proompter_state) abort
  if len(a:value) == 0
    throw 'Proompter: empty input value'
  endif

  let l:model_name = a:configurations.select.model_name
  let l:model = deepcopy(a:configurations.models[l:model_name])
  let l:model.data.model = l:model_name

  let l:prompt = get(l:model.data, 'prompt', '')

  ""
  " Next is all about setting `l:model.data.prompt`
  if type(get(l:model, 'prompt_callbacks')) == v:t_dict
    let l:callbacks_results = {
          \   'preamble': '',
          \   'context': '',
          \   'input': '',
          \ }

    if type(get(l:model.prompt_callbacks, 'preamble')) == v:t_func
      let l:callbacks_results.preamble .= l:model.prompt_callbacks.preamble(a:configurations, a:state)
    endif

    if type(get(l:model.prompt_callbacks, 'context')) == v:t_func
      let l:callbacks_results.context .= l:model.context_callbacks.context(a:configurations, a:state)
    endif

    if type(get(l:model.prompt_callbacks, 'input')) == v:t_func
      let l:callbacks_results.input .= l:model.prompt_callbacks.input(a:value, a:configurations, a:state)
    endif

    if type(get(l:model.prompt_callbacks, 'post')) == v:t_func
      let l:prompt .= l:model.prompt_callbacks.post(l:callbacks_results, a:configurations, a:state)
    else
      let l:prompt .= l:callbacks_results.preamble
      let l:prompt .= l:callbacks_results.context
      let l:prompt .= l:callbacks_results.input
    endif
  else
    let l:prompt .= a:value
  endif
  let l:model.data.prompt = l:prompt

  call add(a:state.messages, {
        \   'message': {
        \     'role': 'user',
        \     'content':  a:value
        \   },
        \ })

  let l:post_payload = proompter#format#HTTPPost(l:model.data, a:configurations)

  let l:channel = proompter#channel#GetOrSetOpen(a:configurations, a:state)

  call ch_sendraw(l:channel, l:post_payload)
endfunction

""
" Parameter: {string} value - What will eventually be sent to LLM
" Parameter: {define__configurations} configurations
"
" Example:
"
" ```vim
" :call proompter#SendPrompt('Tell me in one sentence why Bash is the best scripting language')
" ```
"
" Throw: when `value` is empty or zero length
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
function! proompter#SendPrompt(value, configurations = g:proompter, state = g:proompter_state) abort
  let l:api_endpoint = split(a:configurations.api.url, '/')[-1]
  if l:api_endpoint == 'chat'
    return proompter#SendPromptToChat(a:value, a:configurations, a:state)
  elseif l:api_endpoint == 'generate'
    return proompter#SendPromptToGenerate(a:value, a:configurations, a:state)
  endif
  throw 'Nothing implemented for API endpoint in  ->' . a:configurations.api.url
endfunction

""
" Send range or visually selected text to LLM
"
" Parameter: {string} prefix_input Optional text prefixed to line range
" Parameter: {define__configurations}
"
" Example:
"
" ```vim
" :'<,'>call proompter#SendHighlightedText()
"
" :69,420call proompter#SendHighlightedText()
"
" :call proompter#SendHighlightedText('What does this line do?')
" ```
"
" Throw: selection is zero length
"
" See: {docs} :help optional-function-argument
function! proompter#SendHighlightedText(prefix_input = '', configurations = g:proompter) abort range
  let l:selection = getline(a:firstline, a:lastline)
  if len(a:prefix_input)
    let l:selection = [a:prefix_input, ''] + l:selection
  endif
  let l:value = join(l:selection, "\n")
  call proompter#SendPrompt(l:value, a:configurations)
endfunction

""
" Wrapper for `ch_close` for whatever channel is in `a:state.channel`
function! proompter#cancel(state = g:proompter_state, configurations = g:proompter) abort
  call ch_close(a:state.channel)
endfunction

""
"
function! proompter#load(configurations = g:proompter, state = g:proompter_state) abort
  let l:model_data = { "model": a:configurations.select.model_name }

  let l:endpoint = split(a:configurations.api.url, '/')[-1]
  if l:endpoint == 'chat'
    let l:model_data.messages = []
  elseif l:endpoint == 'generate'
    let l:model_data.prompt = ''
  else
    throw 'Unknown endpoing in -> a:configurations.api.url'
  endif

  let l:post_payload = proompter#format#HTTPPost(l:model_data, a:configurations)

  let l:channel = proompter#channel#GetOrSetOpen(a:configurations, a:state)

  call ch_sendraw(l:channel, l:post_payload)
endfunction

""
"
function! proompter#unload(configurations = g:proompter, state = g:proompter_state) abort
  let l:model_data = {
        \   "model": a:configurations.select.model_name,
        \   "keep_alive": 0,
        \ }

  let l:endpoint = split(a:configurations.api.url, '/')[-1]
  if l:endpoint == 'chat'
    let l:model_data.messages = []
  elseif l:endpoint == 'generate'
    let l:model_data.prompt = ''
  else
    throw 'Unknown endpoing in -> a:configurations.api.url'
  endif

  let l:post_payload = proompter#format#HTTPPost(l:model_data, a:configurations)

  let l:channel = proompter#channel#GetOrSetOpen(a:configurations, a:state)

  call ch_sendraw(l:channel, l:post_payload)
endfunction

" vim: expandtab
