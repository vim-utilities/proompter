#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


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
"       `pre`, `prompt`, and `input`
"
"       else `g:proompter.models['model_name'].prompt_callbacks` is undefined
"       `g:proompter.models['model_name'].data.prompt` is prepended to `value`
"       before being sent to LLM at `g:proompter.api.url` via channel proxy
"
" Dev: without the slicing output of `shellescape` the append/prepend-ed
"      single-quotes which ain't gonna be good within a larger JSON object
function! proompter#SendPrompt(value, configurations = g:proompter) abort
  if len(a:value) == 0
    throw 'Proompter: empty input value'
  endif

  let l:model_name = a:configurations.select.model_name
  let l:model = deepcopy(a:configurations.models[l:model_name])
  let l:model.data.model = l:model_name

  ""
  " Next is all about setting `l:model.data.prompt`
  if type(get(l:model, 'prompt_callbacks')) == type({})
    let l:callbacks_results = {
          \   'pre': '',
          \   'prompt': '',
          \   'input': '',
          \ }

    let l:function_type = type(function("tr"))

    if type(get(l:model.prompt_callbacks, 'pre')) == l:function_type
      let l:callbacks_results.pre .= l:model.prompt_callbacks.pre()
    endif

    if type(get(l:model.prompt_callbacks, 'prompt')) == l:function_type
      let l:callbacks_results.prompt .= l:model.prompt_callbacks.prompt(l:model.data.prompt)
    endif

    if type(get(l:model.prompt_callbacks, 'input')) == l:function_type
      let l:callbacks_results.input .= l:model.prompt_callbacks.input(a:value)
    endif

    if type(get(l:model.prompt_callbacks, 'post')) == l:function_type
      let l:model.data.prompt = l:model.prompt_callbacks.post(l:callbacks_results)
    else
      let l:prompt = l:callbacks_results.pre
      let l:prompt .= l:callbacks_results.prompt
      let l:prompt .= l:callbacks_results.input
      let l:model.data.prompt = l:prompt
    endif
  else
    let l:model.data.prompt .= a:value
  endif

  call add(g:proompter_state.history, { "type": "prompt", "value":  a:value })

  let l:post_payload = proompter#format#HTTPPost(l:model.data, a:configurations)

  let l:channel = proompter#channel#GetOrSetOpen(a:configurations)

  call ch_sendraw(l:channel, l:post_payload)
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
function proompter#cancel(state = g:proompter_state, configurations = g:proompter) abort
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
