#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter



""
" Return start of prompt with content similar to following;
"
" ```
" [
"   {
"     'role': 'system',
"     'content': 'You an expert with javascript and delight in solving problems succinctly!',
"   },
" ]
" ```
"
" Parameter: {dictionary} kwargs - Has the following key/value pares defined
"
"   - {define__configurations} configurations - Dictionary
"   - {define__proompter_state} state - Dictionary
"   - {string} filetype - What file type is operated on
"
" Example: configuration snippet
"
" ```vim
" let g:proompter = {
"       \   'select': {
"       \     'model_name': 'codellama',
"       \   },
"       \   'models': {
"       \     'codellama': {
"       \       'prompt_callbacks': {
"       \         'preamble': { configurations, state ->
"       \           proompter#callback#prompt#chat#Preamble({
"       \             'configurations': configurations,
"       \             'state': state,
"       \             'filetype': 'javascript',
"       \           })
"       \         },
"       \       },
"       \     },
"       \   },
"       \ }
" ```
function! proompter#callback#prompt#chat#Preamble(kwargs) abort
  let l:filetype = get(a:kwargs, 'filetype', &filetype)
  if !len(l:filetype)
    return []
  endif

  return [
        \   {
        \     'role': 'system',
        \     'content': 'You are an expert with ' . l:filetype
        \   },
        \ ]
endfunction

""
" Return no more than `a:kwargs.context_size` last past prompt/response-s
"
" ```
" [
"   {
"     'role': 'user',
"     'content': 'Tell me in one sentence why Vim is the best text editor.',
"   },
"   {
"     'role': 'assistant',
"     'content': 'Vim is the best!',
"   },
" ]
" ```
"
" Parameter: {dictionary} kwargs - Has the following key/value pares defined
"
"   - {define__configurations} configurations - Dictionary
"   - {define__proompter_state} state - Dictionary
"   - {number} context_size - Max prompt/response results that are re-shared
"
" Warning: expects `a:kwargs.state.messages` to be dictionary list _shaped_
" similar to;
"
" ```
" [
"   {
"     "message": {
"       "role": "user",
"       "content": "... Maybe a question about a technical topic...",
"     },
"   },
"   {
"     "message": {
"       "role": "assistant",
"       "content": "Are your finger-tips talking to you too?",
"     },
"   },
" ]
" ```
"
" Example: configuration snippet
"
" ```vim
" let g:proompter = {
"       \   'select': {
"       \     'model_name': 'codellama',
"       \   },
"       \   'models': {
"       \     'codellama': {
"       \       'prompt_callbacks': {
"       \         'context': { configurations, state ->
"       \           proompter#callback#prompt#chat#Context({
"       \             'configurations': configurations,
"       \             'state': state,
"       \             'context_size': 5,
"       \           })
"       \         },
"       \       },
"       \     },
"       \   },
"       \ }
" ```
function! proompter#callback#prompt#chat#Context(kwargs) abort
  let l:context_size = get(a:kwargs, 'context_size', 0)
  let l:index_start = max([len(a:kwargs.state.messages) - l:context_size, 0])
  let l:messages = a:kwargs.state.messages[l:index_start:]
  if !len(l:messages)
    return []
  endif

  return mapnew(l:messages, { _index, entry ->
        \   { 'role': entry.message.role, 'content': entry.message.content }
        \ })
endfunction

""
" Returns a dictionary list formatted from `input` similar to;
"
" ```
" [
"   {
"     'role': 'user',
"     'content': 'Tell me in one sentence why Vim is the best editor for programming.',
"   }
" ]
" ```
"
" ... Entry added to `a:state.messages` will have a format similar to;
"
" ```
" {
"   'model': a:configurations.select.model_name,
"   'created_at': strftime('%FT%T.') . '000000000Z',
"   'message': {
"     'role': 'user',
"     'content': a:input,
"     'image': v:null,
"   }
" }
" ```
"
" Parameter: {string} `value` Text to prompt LLM with
" Parameter: {define__configurations} `configurations` Ignored
" Parameter: {define__proompter_state} `state` Ignored
"
" Example: configuration snippet
"
" ```vim
" let g:proompter = {
"       \   'select': {
"       \     'model_name': 'codellama',
"       \   },
"       \   'models': {
"       \     'codellama': {
"       \       'prompt_callbacks': {
"       \         'input': proompter#callback#prompt#chat#Input,
"       \       },
"       \     },
"       \   },
"       \ }
" ```
"
" See: {docs} :help strftime()
" See: {docs} :help reltime()
"
" TODO: preform feature detection for `strftime` and `reltime`
function! proompter#callback#prompt#chat#Input(input, configurations, state, ...) abort
  let l:entry = {
        \   'model': a:configurations.select.model_name,
        \   'created_at': strftime('%FT%T.') . reltime()[1] . 'Z',
        \   'message': {
        \     'role': 'user',
        \     'content': a:input,
        \     'image': v:null,
        \   },
        \ }

  " call add(a:state.messages, l:entry)

  return [{ 'role': l:entry.message.role, 'content': l:entry.message.content }]
endfunction

""
" Merge together outputs from other prompt callback functions and write to
" defined output buffer before returning list of messages to send to LLM
"
" Parameter: {dictionary} kwargs - Has the following defined
"
"   - {dictionary} data - with `preamble`, `context`, and `input`
"     keys pointing to string values.
"   - {dictionary} out_bufnr - buffer number used for output, if `v:null` one
"     will be created automatically via `proompter#lib#GetOrMakeProomptBuffer`
"     with the name "proompt-log.md", or you man set a {string} value to
"     customize the buffer name.
"
" Example: configuration snippet
"
" ```vim
" let g:proompter = {
"       \   'select': {
"       \     'model_name': 'codellama',
"       \   },
"       \   'models': {
"       \     'codellama': {
"       \       'prompt_callbacks': {
"       \         'post': { prompt_callbacks_data, configurations, state ->
"       \           proompter#callback#prompt#chat#Post({
"       \             'data': prompt_callbacks_data,
"       \             'configurations': configurations,
"       \             'state': state,
"       \             'out_bufnr': v:null,
"       \           })
"       \         },
"       \       },
"       \     },
"       \   },
"       \ }
" ```
function! proompter#callback#prompt#chat#Post(kwargs) abort
  let l:out_bufnr = get(a:kwargs, 'out_bufnr', v:null)
  if l:out_bufnr == v:null || type(l:out_bufnr) == v:t_string
    let l:out_bufnr = proompter#lib#GetOrMakeProomptBuffer(l:out_bufnr)
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

  call proompter#lib#ConcatenateWithLastLineOfBuffer(
        \   l:out_bufnr,
        \   join(l:prompt_heading_lines, "\n")
        \ )

  let l:keys = [ 'preamble', 'context', 'input' ]
  let l:messages = []
  call foreach(l:keys, { _index, key ->
        \   extend(l:messages, get(a:kwargs.data, key, []))
        \ })
  return l:messages
endfunction

" vim: expandtab