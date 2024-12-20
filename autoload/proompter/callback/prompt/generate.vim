#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter
"
" These are indented to be used when `g:proompter.select.completion_endpoint`
" is `generate`



""
" Return start of prompt with content similar to following >
"   You an expert with javascript and delight in solving problems succinctly!
"
"   Content between "<HISTORY>" and "</HISTORY>"  may provide additional
"   context to the following input.
"
"   Past output from you will be surrounded by "<RESPONSE>" and "</RESPONSE>"
"   tags, please consider it but as suspect.
"
"   Input from me will be surrounded by "<PROOMPT>" and "</PROOMPT>" tags,
"   please pay most attention to the last instance.
" <
"
" Parameter: {kwargs} |dictionary| has the following key/value pares defined;
" - `filetype` |string| of what file type is operated on
" - `history_tags` |dictionary| with `start` and `stop` values defined to help
"   clue-in LLM of past context
" - `input_tags` |dictionary| with `start` and `stop` values defined to help
"   LLM focus on latest input
" - `response_tags` |dictionary| with `start` and `stop` values defined to
"   help LLM remember previous outputs
" - `configurations` |ProompterConfigurations| ignored for now
" - `state` |ProompterState| ignored for now
"
" Example: configuration snippet~ >
"   let g:proompter = {
"         \   'select': {
"         \     'model_name': 'codellama',
"         \     'completion_endpoint': 'generate',
"         \   },
"         \   'api': {
"         \     'url': 'http://127.0.0.1:11434',
"         \     'prompt_callbacks': {
"         \       'generate': {
"         \         'preamble': { _configurations, _state ->
"         \           proompter#callback#prompt#generate#Preamble({
"         \             'filetype': 'javascript',
"         \             'history_tags': {
"         \               'start': '<HISTORY>',
"         \               'end': '</HISTORY>'
"         \             },
"         \             'input_tags': {
"         \               'start': '<PROOMPT>',
"         \               'end': '</PROOMPT>'
"         \             },
"         \             'response_tags': {
"         \               'start': '<RESPONSE>',
"         \               'end': '</RESPONSE>'
"         \             },
"         \           })
"         \         },
"         \       },
"         \     },
"         \   },
"         \ }
" <
"
" See: tests~
" - tests/units/autoload_proompter_callback_prompt_generate_Preamble.vader
"
" @public
function! proompter#callback#prompt#generate#Preamble(kwargs) abort
  let l:lines = []

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

    let l:response_tags = get(a:kwargs, 'response_tags', {})
    let l:response_tag__start = get(l:response_tags, 'start', '')
    let l:response_tag__stop = get(l:response_tags, 'stop', '')
    if len(l:response_tag__start) && len(l:response_tag__stop)
      let l:lines += [
            \   '',
            \   join([
            \     'Past output from you will be surrounded by',
            \     l:response_tag__start,
            \     'and',
            \     l:response_tag__stop,
            \     'tags, please consider it but as suspect.'
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
  endif

  return join(l:lines, "\n")
endfunction

""
" Returns a string formatted from `kwargs.input` and `kwargs.input_tag` >
"   <HISTORY>
"   <PROOMPT>
"   Tell me in one sentence why Vim is the best editor for programming.
"   </PROOMPT>
"   <RESPONSE>
"   Vim is the best!
"   </RESPONSE>
"   </HISTORY>
" <
"
" Parameter: {kwargs} |dictionary| Has the following key/value pares defined;
" - `value` |string| to prompt LLM with
" - `history_tags` with `start` and `stop` values defined to help clue-in LLM
"   of past context
" - `input_tags` with `start` and `stop` values defined to help LLM focus on
"   latest input
" - `response_tags` with `start` and `stop` values defined to help LLM
"   remember previous outputs
" - `configurations` |ProompterConfigurations| ignored for now
" - `state` |ProompterState| dictionary that may contain a list of `messages`
"
" Warning: expects `a:kwargs.state.messages` to be dictionary list _shaped_
" similar to >
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
"         \   'select': {
"         \     'model_name': 'codellama',
"         \     'completion_endpoint': 'generate',
"         \   },
"         \   'api': {
"         \     'url': 'http://127.0.0.1:11434',
"         \     'prompt_callbacks': {
"         \       'generate': {
"         \         'context': { _configurations, state ->
"         \           proompter#callback#prompt#generate#Context({
"         \             'state': state,
"         \             'context_size': 5,
"         \             'history_tags': {
"         \               'start': '<HISTORY>',
"         \               'end': '</HISTORY>'
"         \             },
"         \             'input_tags': {
"         \               'start': '<PROOMPT>',
"         \               'end': '</PROOMPT>'
"         \             },
"         \             'response_tags': {
"         \               'start': '<RESPONSE>',
"         \               'end': '</RESPONSE>'
"         \             },
"         \           })
"         \         },
"         \       },
"         \     },
"         \   },
"         \ }
" <
"
" Dev: note to remove tags surrounding later via something like >
"   echo substitute(_input_, '</\?PROOMPT>', '', 'g')
" <
"
" See: documentation+
" - |proompter#parse#MessageOrResponseFromAPI|
"
" See: tests+
" - tests/units/autoload_proompter_callback_prompt_generate_Context.vader
"
" @public
function! proompter#callback#prompt#generate#Context(kwargs) abort
  let l:lines = []

  let l:context_size = get(a:kwargs, 'context_size', 0)
  let l:messages = a:kwargs.state.messages[max([len(a:kwargs.state.messages) - l:context_size, 0]):]

  if len(l:messages)
    let l:history_tags = get(a:kwargs, 'history_tags', {})
    let l:history_tag__start = get(a:kwargs.history_tags, 'start', '')
    let l:history_tag__stop = get(a:kwargs.history_tags, 'stop', '')
    if len(l:history_tag__start) && len(l:history_tag__stop)
      call add(l:lines, l:history_tag__start)
    endif

    let l:input_tags = get(a:kwargs, 'input_tags', {})
    let l:input_tag__start = get(a:kwargs.input_tags, 'start', '')
    let l:input_tag__stop = get(a:kwargs.input_tags, 'stop', '')

    let l:response_tags = get(a:kwargs, 'response_tags', {})
    let l:response_tag__start = get(a:kwargs.response_tags, 'start', '')
    let l:response_tag__stop = get(a:kwargs.response_tags, 'stop', '')

    if len(input_tag__start) && len(input_tag__stop) && len(response_tag__start) && len(response_tag__stop)
      for l:entry in l:messages
        if l:entry.role == 'user'
          call add(l:lines, l:input_tag__start . l:entry.message.content l:input_tag__stop)
        elseif l:entry.role == 'assistant'
          call add(l:lines, l:response_tag__start . l:entry.message.content l:response_tag__stop)
        else
          echow 'Unknown entry.role ->' l:entry
          call add(l:lines, l:entry.content)
        endif
      endfor
    else
      call extend(l:lines, mapnew(l:messages, { _index, entry ->
            \   entry.message.role . ': ' . entry.message.content
            \ }))
    endif

    if len(l:history_tag__start) && len(l:history_tag__stop)
      call add(l:lines, l:history_tag__stop)
    endif
  endif

  return join(l:lines, "\n")
endfunction

""
" Returns a string formatted from `kwargs.input` and `kwargs.input_tag` >
"   <PROOMPT>
"   Tell me in one sentence why Vim is the best editor for programming.
"   </PROOMPT>
" <
"
" Parameter: {kwargs} |dictionary| Has the following key/value pares defined;
" - `value` |string| text to prompt LLM with
" - `input_tags` dictionary with `start` and `stop` values defined to help LLM
"   focus on latest input
" - `configurations` |ProompterConfigurations| ignored for now
" - `state` |ProompterState| ignored for now
"
" Example: configuration snippet~ >
"   let g:proompter = {
"         \   'select': {
"         \     'model_name': 'codellama',
"         \     'completion_endpoint': 'generate',
"         \   },
"         \   'api': {
"         \     'url': 'http://127.0.0.1:11434',
"         \     'prompt_callbacks': {
"         \       'generate': {
"         \         'input': { value, _configurations, _state ->
"         \           proompter#callback#prompt#generate#Input({
"         \             'value': value,
"         \             'input_tags': {
"         \               'start': '<PROOMPT>',
"         \               'end': '</PROOMPT>'
"         \             },
"         \           })
"         \         },
"         \       },
"         \     },
"         \   },
"         \ }
" <
"
" Dev: note to remove tags surrounding later via something like >
"   echo substitute(_input_, '</\?PROOMPT>', '', 'g')
" <
"
" See: tests~
" - tests/units/autoload_proompter_callback_prompt_generate_Input.vader
"
" @public
function! proompter#callback#prompt#generate#Input(kwargs) abort
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
" @dict PromptCallbackDataGenerate

""
" Merge together outputs from other prompt callback functions and write to
" defined output buffer before returning newline separated string for LLM
"
" Parameter:~
" - {kwargs} |dictionary| Has the following defined;
"   - `data` |PromptCallbackDataGenerate| with `preamble`, `context`,
"     `prompt`, and `input` keys pointing to values.
"   - `out_bufnr` - buffer |number| used for output, if |v:null| one will be
"     created automatically via |proompter#buffer#MakeProomptLog| with the
"     name "proompt-log.md", or you man set a string value to customize the
"     buffer name.
"   - `configurations` |ProompterConfigurations| ignored for now
"   - `state` |ProompterState| ignored for now
"
" Example: configuration snippet~ >
"   let g:proompter = {
"         \   'select': {
"         \     'model_name': 'codellama',
"         \     'completion_endpoint': 'generate',
"         \   },
"         \   'api': {
"         \     'url': 'http://127.0.0.1:11434',
"         \     'prompt_callbacks': {
"         \       'generate': {
"         \         'post': { callbacks_data, _configurations, _state ->
"         \           proompter#callback#prompt#generate#Post({
"         \             'data': callbacks_data,
"         \             'out_bufnr': v:null,
"         \           })
"         \         },
"         \       },
"         \     },
"         \   },
"         \ }
" <
"
" See: tests~
" - tests/units/autoload_proompter_callback_prompt_generate_Post.vader
"
" @public
function! proompter#callback#prompt#generate#Post(kwargs) abort
  let l:lines = []

  if len(a:kwargs.data.preamble)
    let l:lines += [ a:kwargs.data.preamble, '' ]
  endif

  if len(a:kwargs.data.context)
    let l:lines += [ a:kwargs.data.context, '' ]
  endif

  if len(a:kwargs.data.input)
    let l:lines += [ a:kwargs.data.input, '' ]
  endif

  let l:out_bufnr = get(a:kwargs, 'out_bufnr', v:null)
  if l:out_bufnr == v:null || type(l:out_bufnr) == v:t_string
    let l:out_bufnr = proompter#buffer#MakeProomptLog(l:out_bufnr)
  endif

  let l:prompt_heading_lines = add([
        \   '## Prompt ' . strftime("%Y-%m-%d %H:%M:%S"),
        \   '',
        \   '',
        \ ], a:kwargs.data.input)

  if getbufinfo(l:out_bufnr)[0].linecount > 1
    let l:prompt_heading_lines = extend([''], l:prompt_heading_lines)
  endif
  call extend(l:prompt_heading_lines, ['', ''])

  call proompter#buffer#ConcatenateWithLastLine(
        \   l:out_bufnr,
        \   join(l:prompt_heading_lines, "\n")
        \ )

  return join(l:lines, "\n")
endfunction

" vim: expandtab
