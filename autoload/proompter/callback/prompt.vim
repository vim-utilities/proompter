#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
" When there is no messages, or messages would cause `prompt_callbacks.post` to
" drop this prefix, return start of prompt with content similar to following;
"
"   You an expert with javascript and delight in solving problems succinctly!
"
"   Content between "<HISTORY>" and "</HISTORY>"  may provide
"   additional context to the following input.
"
"   Input will be surrounded by "<PROOMPT>" and "</PROOMPT>" tags,
"   please pay most attention to the last instance.
"
" Parameter: {dictionary} kwargs - Has the following key/value pares defined
"
"   - {define__configurations} configurations - Dictionary
"   - {define__proompter_state} state - Dictionary
"   - {number} context_size - Max prompt/response results that are re-shared
"   - {string} filetype - What file type is operated on
"   - {dictionary} history_tags - With `start` and `stop` values defined to
"     help clue-in LLM of past context
"   - {dictionary} input_tags - With `start` and `stop` values defined to help
"     LLM focus on latest input
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
"       \         'pre': { configurations, state ->
"       \           proompter#callback#prompt#Generate_Pre({
"       \             'configurations': configurations,
"       \             'state': state,
"       \             'context_size': 5,
"       \             'filetype': 'javascript',
"       \             'history_tags': { 'start': '<HISTORY>', 'end': '</HISTORY>'},
"       \             'input_tags': { 'start': '<PROOMPT>', 'end': '</PROOMPT>'},
"       \           })
"       \         },
"       \       },
"       \     },
"       \   },
"       \ }
" ```
function! proompter#callback#prompt#Generate_Pre(kwargs) abort
  let l:lines = []

  if a:kwargs.context_size >= len(a:kwargs.state.messages)
    return join(l:lines, "\n")
  endif

  let l:starter = 'You are an expert'
  let l:filetype = get(a:kwargs, 'filetype')
  if type(l:filetype) == v:t_string && len(a:kwargs.filetype)
    let l:starter .= ' with ' . l:filetype
  endif

  let l:lines += [ l:starter . ' and delight in solving problems succinctly!' ]

  let l:history_tags = get(a:kwargs, 'history_tags', {})
  let l:history_tag__start = get(a:kwargs.history_tags, 'start', '')
  let l:history_tag__stop = get(a:kwargs.history_tags, 'stop', '')
  if len(l:history_tag__start) && len(l:history_tag__stop)
    let l:lines += [
          \   '',
          \   join([
          \     'Content between',
          \     l:history_tag__start,
          \     'and',
          \     l:history_tag__stop,
          \     'may provide additional context to the following input.'
          \   ], ' '),
          \ ]
  endif

  let l:input_tags = get(a:kwargs, 'input_tags', {})
  let l:input_tag__start = get(l:input_tags, 'start', '')
  let l:input_tag__stop = get(l:input_tags, 'stop', '')
  if len(l:input_tag__start) && len(l:input_tag__stop)
    let l:lines += [
          \   '',
          \   join([
          \     'Input will be surrounded by',
          \     l:input_tag__start,
          \     'and',
          \     l:input_tag__stop,
          \     'tags, please pay most attention to the last instance.'
          \   ], ' '),
          \ ]
  endif

  return join(l:lines, "\n")
endfunction

""
" Returns a string formatted from `kwargs.input` and `kwargs.input_tag`
"
"   <PROOMPT>
"   Tell me in one sentence why Vim is the best editor for programming.
"   </PROOMPT>
"
" Parameter: {dictionary} kwargs - Has the following key/value pares defined
"
"   - {string} value - Text to prompt LLM with
"   - {dictionary} input_tags - With `start` and `stop` values defined to help
"     LLM focus on latest input
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
"       \         'input': { value, configurations, state ->
"       \           proompter#callback#prompt#Generate_Input({
"       \             'value': value,
"       \             'configurations': configurations,
"       \             'state': state,
"       \             'input_tags': { 'start': '<PROOMPT>', 'end': '</PROOMPT>'},
"       \           })
"       \         },
"       \       },
"       \     },
"       \   },
"       \ }
" ```
"
" Dev: remove tags surrounding later via something like;
"
" ```vim
" echo substitute(_input_, '</\?PROOMPT>', '', 'g')
" ```
function! proompter#callback#prompt#Generate_Input(kwargs) abort
  let l:lines = []

  let l:input_tags = get(a:kwargs, 'input_tags', {})
  let l:input_tag__start = get(l:input_tags, 'start', '')
  let l:input_tag__stop = get(l:input_tags, 'stop', '')
  if len(l:input_tag__start) && len(l:input_tag__stop)
    let l:lines += [
          \   l:input_tag__start,
          \   a:kwargs.value,
          \   l:input_tag__stop,
          \ ]
  else
    let l:lines += [ a:kwargs.value ]
  endif

  return join(l:lines, "\n")
endfunction

""
" Merge together outputs from other prompt callback functions as well as
" history of past input/response-s into a single string to pass to LLM.
"
" Parameter: {dictionary} kwargs - Has the following defined
"
"   - {dictionary} data - with `pre`, `prompt`, and `input` keys pointing to
"     string values.
"   - {number} context_size - Max results from `a:kwargs.state.messages` to
"     provide LLM context.
"   - {dictionary} out_bufnr - buffer number used for output, if `v:null` one
"     will be created automatically via `proompter#lib#GetOrMakeProomptBuffer`
"     with the name "proompt-log.md", or you man set a {string} value to
"     customize the buffer name.
"   - {dictionary} history_tags - With `start` and `stop` values defined to
"     help clue-in LLM of past context.
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
"       \         'post': { prompt_callbacks_data, configurations, state ->
"       \           proompter#callback#prompt#Generate_Post({
"       \             'data': prompt_callbacks_data,
"       \             'configurations': configurations,
"       \             'state': state,
"       \             'context_size': 5,
"       \             'history_tags': { 'start': '<HISTORY>', 'end': '</HISTORY>'},
"       \             'out_bufnr': v:null,
"       \           })
"       \         },
"       \       },
"       \     },
"       \   },
"       \ }
" ```
function! proompter#callback#prompt#Generate_Post(kwargs) abort
  let l:context_size = get(a:kwargs, 'context_size', 0)
  let l:history_lines = a:kwargs.state.messages[max([len(a:kwargs.state.messages) - l:context_size, 0]):]

  let l:lines = []

  if len(a:kwargs.data.pre)
    let l:lines += [ a:kwargs.data.pre, '' ]
  endif

  if len(l:history_lines)
    let l:history_tags = get(a:kwargs, 'history_tags', {})
    let l:history_tag__start = get(a:kwargs.history_tags, 'start', '')
    let l:history_tag__stop = get(a:kwargs.history_tags, 'stop', '')
    if len(l:history_tag__start) && len(l:history_tag__stop)
      let l:pattern = '^\(\(' . history_tag__start . '\)\|\(' . history_tag__stop . '\)\)$'

      let l:lines += [
            \   l:history_tag__start,
            \   map(l:history_lines, { _index, history_data ->
            \     substitute(history_data.message.content, l:pattern, '', 'g')
            \   }),
            \   l:history_tag__stop,
            \ ]
    else
      let l:lines += map(l:history_lines, { _index, history_data -> history_data.message.content })
    endif
  endif

  if len(a:kwargs.data.prompt)
    let l:lines += [ a:kwargs.data.prompt, '' ]
  endif

  if len(a:kwargs.data.input)
    let l:lines += [ a:kwargs.data.input, '' ]
  endif

  let l:out_bufnr = get(a:kwargs, 'out_bufnr', v:null)
  if l:out_bufnr == v:null || type(l:out_bufnr) == v:t_string
    let l:out_bufnr = proompter#lib#GetOrMakeProomptBuffer(l:out_bufnr)
  endif

  let l:prompt_heading_lines = [
        \   '## Prompt ' . strftime("%Y-%m-%d %H:%M:%S"),
        \   '',
        \   '',
        \ ]

  ""
  " Figure out if we're starting the Vim buffer or appending more text
  if len(getbufline(l:out_bufnr, 0, '$')) <= 1
    call setbufline(l:out_bufnr, '$', l:prompt_heading_lines)
    for l:line in l:lines
      call setbufline(l:out_bufnr, '$', split(l:line, "\n"))
    endfor
  else
    call appendbufline(l:out_bufnr, '$', [''] + l:prompt_heading_lines)
    call appendbufline(l:out_bufnr, '$', split(a:kwargs.data.input, "\n"))
  endif
  call appendbufline(l:out_bufnr, '$', ['', ''])

  return join(l:lines, "\n")
endfunction

" vim: expandtab
