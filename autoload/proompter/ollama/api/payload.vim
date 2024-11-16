#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter

""
" TODO: endpoints that may need wrapper functions~
" - https://github.com/ollama/ollama/blob/main/docs/api.md#check-if-a-blob-exists


""
" Return |dictionary| with `url` and request `options` defined.
"
" Parameter: {kwargs} with following properties~
" - `prompt` |string| input LLM should respond to
" - `suffix` |string|
" - `images` |list| optional Base64 encoded images
" - `format` |string| currently only `json` is a valid value
" - `options` |dictionary| `Modelfile` edits
" - `stream` |Boolean| if `tools` are detected then automatically sets to
"   `v:false`, otherwise attempts to read `configurations` or defaults to
"   `v:true`
" - `template` optional override for what `Modelfile` defines
" - `context` |list| optional floating point numbers used to keep a short
"   conversational memory between prompts
" - `raw` |Boolean| default `v:true` to prevent additional prompt formatting
" - `keep_alive` |string| how long model will stay loaded into memory
" - `configurations` |ProompterConfigurations| default `g:proompter`, reads
"   `.selected.model_name`, `.channel.address`, `.api.url`, and
"   `.models[model_name].data`, without mutaiton
"
" Note: when `suffix`, `format`, `options`, `system`, `stream`, `template`,
" `raw`, and `keep_alive` when not set as `kwargs` properties, this function
" will attempt to read defaults from `configurations.models[model_name].data`
"
" Example: configurations~ >
"   let configurations = {
"         \   'select': {
"         \     'model_name': 'codellama',
"         \     'completion_endpoint': 'chat',
"         \   },
"         \   'api': {
"         \     'url': 'http://127.0.0.1:11434',
"         \   },
"         \   'channel': {
"         \     'address': '127.0.0.1:41968',
"         \   },
"         \   'models': {
"         \     'codellama': {
"         \       'data': {
"         \         'stream': v:true,
"         \       },
"         \     },
"         \   },
"         \ }
" <
"
" Example: build payload data~ >
"   let payload_data = proompter#ollama#api#payload#Generate({
"         \   'prompt': 'Write a haiku about the Vim text editor',
"         \   'configurations': g:proompter,
"         \ })
" <
"
" Example: result data structure~ >
"   {
"     'url': 'http://127.0.0.1:11434/api/generate',
"     'options': {
"       'method': 'post',
"       'headers': {
"         'Host': '127.0.0.1:41968',
"         'Content-Type': 'application/json',
"       },
"       'body': {
"         'model': 'codellama',
"         'stream': v:true,
"         'prompt': 'Write a haiku about the Vim text editor',
"       },
"     },
"   }
" <
"
" @throws ProompterError `Empty prompt`
"
" See: functions~
" - |proompter#http#encode#Request|
"
" See: links~
" - https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-completion
"
" See: tests~
" - tests/mocks/autoload_proompter_ollama_api_payload_Generate.vader
"
" @public
function! proompter#ollama#api#payload#Generate(kwargs = {}) abort
  let l:prompt = get(a:kwargs, 'prompt', [])
  if !len(l:prompt)
    throw 'ProompterError Empty prompt'
  endif

  let l:configurations = get(a:kwargs, 'configurations', g:proompter)

  let l:url_data = l:configurations.api.url
  if type(l:url_data) == v:t_string
    let l:url_data = proompter#url#FromString(l:url_data)
  elseif type(l:url_data) != v:t_dict
    throw 'ProompterError configurations API URL is not string or dictionary'
  endif

  let l:url_data.pathname = '/api/generate'
  let l:url = proompter#url#ToString(l:url_data)

  let l:result = {
        \   'url': l:url,
        \   'options': {
        \     'method': 'post',
        \     'headers': {
        \       'Host': l:configurations.channel.address,
        \       'Content-Type': 'application/json',
        \     },
        \     'body': {
        \       'model': l:configurations.select.model_name,
        \       'prompt': l:prompt,
        \     },
        \   },
        \ }

  let l:images = get(a:kwargs, 'images', v:null)
  if l:images != v:null && type(l:images) == v:t_list
    let l:result.options.body.images = l:images
  endif

  let l:selected_model = get(get(l:configurations, 'models', {}), l:configurations.select.model_name, {})

  let l:suffix = get(a:kwargs, 'suffix', get(get(l:selected_model, 'data', {}), 'suffix', v:null))
  if l:suffix != v:null && type(l:suffix) == v:t_string
    let l:result.options.body.suffix = l:suffix
  endif

  let l:options = get(a:kwargs, 'options', get(get(l:selected_model, 'data', {}), 'options', v:null))
  if l:options != v:null && type(l:options) == v:t_dict
    let l:result.options.body.options = l:options
  endif

  let l:system = get(a:kwargs, 'system', get(get(l:selected_model, 'data', {}), 'system', v:null))
  if l:system != v:null && type(l:system) == v:t_string
    let l:result.options.body.system = l:system
  endif

  let l:template = get(a:kwargs, 'template', get(get(l:selected_model, 'data', {}), 'template', v:null))
  if l:template != v:null && type(l:template) == v:t_string
    let l:result.options.body.template = l:template
  endif

  let l:stream = get(a:kwargs, 'stream', get(get(l:selected_model, 'data', {}), 'stream', v:null))
  if l:stream != v:null && type(l:stream) == v:t_bool
    let l:result.options.body.stream = l:stream
  endif

  let l:keep_alive = get(a:kwargs, 'keep_alive', get(get(l:selected_model, 'data', {}), 'keep_alive', v:null))
  if l:keep_alive != v:null && type(l:keep_alive) == v:t_bool
    let l:result.options.body.keep_alive = l:keep_alive
  endif

  return l:result
endfunction

""
" Return |dictionary| with `url` and request `options` defined.
"
" Parameter: {kwargs} with following properties~
" - `messages` |string| optional contents of `Modelfile`
" - `tools` |list| requires `stream` to be `v:false` contains |dictionary|
"   list of functions the model may request use of
" - `format` |string| currently only `json` is a valid value
" - `options` |dictionary| `Modelfile` edits
" - `stream` |Boolean| automatically sets to `v:false` if `tools` are defined
" - `keep_alive` |string| how long model will stay loaded into memory
" - `configurations` |ProompterConfigurations| default `g:proompter`, reads
"   `.selected.model_name`, `.channel.address`, `.api.url`, and
"   `.models[model_name].data`, without mutaiton
"
" Note: when `tools`, `format`, `options`, `stream`, and `keep_alive` when not
" set as `kwargs` properties, this function will attempt to read defaults from
" `configurations.models[model_name].data`
"
" Example: configurations~ >
"   let configurations = {
"         \   'select': {
"         \     'model_name': 'codellama',
"         \     'completion_endpoint': 'chat',
"         \   },
"         \   'api': {
"         \     'url': 'http://127.0.0.1:11434',
"         \   },
"         \   'channel': {
"         \     'address': '127.0.0.1:41968',
"         \   },
"         \   'models': {
"         \     'codellama': {
"         \       'data': {
"         \         'stream': v:true,
"         \       },
"         \     },
"         \   },
"         \ }
" <
"
" Example: build payload data~ >
"   let payload_data = proompter#ollama#api#payload#Chat({
"         \   'messages': [
"         \     {
"         \       'role': 'system',
"         \       'content': 'You are an expert poet',
"         \     },
"         \     {
"         \       'role': 'user',
"         \       'content': 'Write a haiku about the Vim text editor',
"         \     },
"         \   ],
"         \   'configurations': g:proompter,
"         \ })
" <
"
" Example: result data structure~ >
"   {
"     'url': 'http://127.0.0.1:11434/api/chat',
"     'options': {
"       'method': 'post',
"       'headers': {
"         'Host': '127.0.0.1:41968',
"         'Content-Type': 'application/json',
"       },
"       'body': {
"         'model': 'codellama',
"         'stream': v:true,
"         'messages': [
"           {
"             'role': 'system',
"             'content': 'You are an expert poet',
"           },
"           {
"             'role': 'user',
"             'content': 'Write a haiku about the Vim text editor',
"           },
"         ],
"       },
"     },
"   }
" <
"
" @throws ProompterError `Non-list messages`
"
" See: functions~
" - |proompter#http#encode#Request|
"
" See: links~
" - https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-chat-completion
"
" See: tests~
" - tests/mocks/autoload_proompter_ollama_api_payload_Chat.vader
"
" @public
function! proompter#ollama#api#payload#Chat(kwargs = {}) abort
  let l:messages = get(a:kwargs, 'messages', [])
  if type(l:messages) != v:t_list
    throw 'ProompterError Non-list messages'
  endif

  let l:configurations = get(a:kwargs, 'configurations', g:proompter)

  let l:url_data = l:configurations.api.url
  if type(l:url_data) == v:t_string
    let l:url_data = proompter#url#FromString(l:url_data)
  elseif type(l:url_data) != v:t_dict
    throw 'ProompterError configurations API URL is not string or dictionary'
  endif

  let l:url_data.pathname = '/api/chat'
  let l:url = proompter#url#ToString(l:url_data)

  let l:result = {
        \   'url': l:url,
        \   'options': {
        \     'method': 'post',
        \     'headers': {
        \       'Host': l:configurations.channel.address,
        \       'Content-Type': 'application/json',
        \     },
        \     'body': {
        \       'model': l:configurations.select.model_name,
        \       'messages': l:messages,
        \     },
        \   },
        \ }

  let l:selected_model = get(get(l:configurations, 'models', {}), l:configurations.select.model_name, {})

  let l:tools = get(a:kwargs, 'tools', v:null)
  if l:tools != v:null && type(l:tools) == v:t_list
    let l:result.options.body['tools'] = l:tools
    let l:result.options.body['stream'] = v:false
  else
    let l:stream = get(a:kwargs, 'stream', get(get(l:selected_model, 'data', {}), 'stream', v:true))
    let l:result.options.body['stream'] = l:stream
  endif

  let l:format = get(a:kwargs, 'format', get(get(l:selected_model, 'data', {}), 'format', v:null))
  if l:format != v:null && type(l:format) == v:t_string
    let l:result.options.body['format'] = l:format
  endif

  let l:options = get(a:kwargs, 'options', get(get(l:selected_model, 'data', {}), 'options', v:null))
  if l:options != v:null && type(l:options) == v:t_dict
    let l:result.options.body['options'] = l:options
  endif

  let l:keep_alive = get(a:kwargs, 'keep_alive', get(get(l:selected_model, 'data', {}), 'keep_alive', v:null))
  if l:keep_alive != v:null && type(l:keep_alive) == v:t_bool
    let l:result.options.body['keep_alive'] = l:keep_alive
  endif

  return l:result
endfunction

""
" Return |dictionary| with `url` and request `options` defined.
"
" Parameter: {kwargs} with following properties~
" - `name` |string| model to create
" - `modelfile` |string| optional contents of `Modelfile`
" - `stream` |Boolean| default `v:true` if `v:false` response will be single
"   JSON object instead of stream
" - `path` |string| `Modelfile` location
" - `configurations` |ProompterConfigurations| default `g:proompter`, reads
"   `.channel.address`, and `.api.url`, without mutation
"
" Example: configurations~ >
"   let configurations = {
"         \   'select': {
"         \     'model_name': 'codellama',
"         \     'completion_endpoint': 'chat',
"         \   },
"         \   'api': {
"         \     'url': 'http://127.0.0.1:11434',
"         \   },
"         \   'channel': {
"         \     'address': '127.0.0.1:41968',
"         \   },
"         \ }
" <
"
" Example: build payload data~ >
"   let payload_data = proompter#ollama#api#payload#Create({
"         \   'name': 'mario',
"         \   'modelfile': join([
"         \     'FROM llama3',
"         \     'SYSTEM You are mario from Super Mario Bros'
"         \   ], "\n"),
"         \   'configurations': g:proompter,
"         \ })
" <
"
" Example: result data structure~ >
"   {
"     'url': 'http://127.0.0.1:11434/api/create',
"     'options': {
"       'method': 'post',
"       'headers': {
"         'Host': '127.0.0.1:41968',
"         'Content-Type': 'application/json',
"       },
"     },
"   }
" <
"
" See: functions~
" - |proompter#http#encode#Request|
"
" See: links~
" - https://github.com/ollama/ollama/blob/main/docs/api.md#create-a-model
"
" See: tests~
" - tests/mocks/autoload_proompter_ollama_api_payload_Create.vader
"
" @public
function! proompter#ollama#api#payload#Create(kwargs = {}) abort
  let l:name = get(a:kwargs, 'name', '')
  if !len(l:name)
    throw 'ProompterError Empty name'
  endif

  let l:configurations = get(a:kwargs, 'configurations', g:proompter)

  let l:url_data = l:configurations.api.url
  if type(l:url_data) == v:t_string
    let l:url_data = proompter#url#FromString(l:url_data)
  elseif type(l:url_data) != v:t_dict
    throw 'ProompterError configurations API URL is not string or dictionary'
  endif

  let l:url_data.pathname = '/api/create'
  let l:url = proompter#url#ToString(l:url_data)

  let l:result = {
        \   'url': l:url,
        \   'options': {
        \     'method': 'post',
        \     'headers': {
        \       'Host': l:configurations.channel.address,
        \       'Content-Type': 'application/json',
        \     },
        \     'body': {
        \       'name': l:name,
        \     },
        \   },
        \ }

  let l:modelfile = get(a:kwargs, 'modelfile', v:null)
  if l:modelfile != v:null && type(l:modelfile) == v:t_string
    let l:result.options.body['modelfile'] = l:modelfile
  endif

  let l:stream = get(a:kwargs, 'stream', v:null)
  if l:stream != v:null && type(l:stream) == v:t_bool
    let l:result.options.body['stream'] = l:stream
  endif

  let l:path = get(a:kwargs, 'path', v:null)
  if l:path != v:null && type(l:path) == v:t_string
    let l:result.options.body['path'] = l:path
  endif

  return l:result
endfunction

""
" Return |dictionary| with `url` and request `options` defined.
"
" Parameter: {kwargs} with following properties~
" - `configurations` |ProompterConfigurations| default `g:proompter`, reads
"   `.channel.address`, and `.api.url`, without mutation
"
" Example: configurations~ >
"   let configurations = {
"         \   'select': {
"         \     'model_name': 'codellama',
"         \     'completion_endpoint': 'chat',
"         \   },
"         \   'api': {
"         \     'url': 'http://127.0.0.1:11434',
"         \   },
"         \   'channel': {
"         \     'address': '127.0.0.1:41968',
"         \   },
"         \ }
" <
"
" Example: build payload data~ >
"   let payload_data = proompter#ollama#api#payload#Tags({
"         \   'configurations': g:proompter,
"         \ })
" <
"
" Example: result data structure~ >
"   {
"     'url': 'http://127.0.0.1:11434/api/tags',
"     'options': {
"       'method': 'get',
"       'headers': {
"         'Host': '127.0.0.1:41968',
"         'Content-Type': 'application/json',
"       },
"     },
"   }
" <
"
" See: functions~
" - |proompter#http#encode#Request|
"
" See: links~
" - https://github.com/ollama/ollama/blob/main/docs/api.md#list-local-models
"
" @public
function! proompter#ollama#api#payload#Tags(kwargs = {}) abort
  let l:configurations = get(a:kwargs, 'configurations', g:proompter)

  let l:url_data = l:configurations.api.url
  if type(l:url_data) == v:t_string
    let l:url_data = proompter#url#FromString(l:url_data)
  elseif type(l:url_data) != v:t_dict
    throw 'ProompterError configurations API URL is not string or dictionary'
  endif

  let l:url_data.pathname = '/api/tags'
  let l:url = proompter#url#ToString(l:url_data)

  let l:result = {
        \   'url': l:url,
        \   'options': {
        \     'method': 'get',
        \     'headers': {
        \       'Host': l:configurations.channel.address,
        \       'Content-Type': 'application/json',
        \     },
        \   },
        \ }

  return l:result
endfunction

""
" Return |dictionary| with `url` and request `options` defined.
"
" Parameter: {kwargs} with following properties~
" - `name` |string| default to `configurations.selected.model_name`, model
"   name to request information about
" - `verbose` |Boolean| default `v:false`, set to `v:true` to return more info
" - `configurations` |ProompterConfigurations| default `g:proompter`, reads
"   `.selected.model_name`, `.channel.address`, and `.api.url`, without
" - `state` |ProompterState| default `g:proompter_state` and currently ignored
"
" Example: configurations~ >
"   let configurations = {
"         \   'select': {
"         \     'model_name': 'codellama',
"         \     'completion_endpoint': 'chat',
"         \   },
"         \   'api': {
"         \     'url': 'http://127.0.0.1:11434',
"         \   },
"         \   'channel': {
"         \     'address': '127.0.0.1:41968',
"         \   },
"         \ }
" <
"
" Example: build payload data~ >
"   let payload_data = proompter#ollama#api#payload#Show({
"         \   'name': 'codellama',
"         \   'verbose': v:true,
"         \   'configurations': g:proompter,
"         \ })
" <
"
" Example: result data structure~ >
"   {
"     'url': 'http://127.0.0.1:11434/api/show',
"     'options': {
"       'method': 'post',
"       'headers': {
"         'Host': '127.0.0.1:41968',
"         'Content-Type': 'application/json',
"       },
"       'body': {
"         'name': 'codellama',
"         'verbose': v:false,
"       },
"     },
"   }
" <
"
" @throws ProompterError `Empty name`
"
" See: functions~
" - |proompter#http#encode#Request|
"
" See: links~
" - https://github.com/ollama/ollama/blob/main/docs/api.md#show-model-information
"
" See: tests~
" - tests/mocks/autoload_proompter_ollama_api_payload_Show.vader
"
" @public
function! proompter#ollama#api#payload#Show(kwargs = {}) abort
  let l:configurations = get(a:kwargs, 'configurations', g:proompter)

  let l:name = get(a:kwargs, 'name', l:configurations.select.model_name)
  if !len(l:name)
    throw 'ProompterError Empty name'
  endif

  let l:verbose = get(a:kwargs, 'verbose', v:false)

  let l:url_data = l:configurations.api.url
  if type(l:url_data) == v:t_string
    let l:url_data = proompter#url#FromString(l:url_data)
  elseif type(l:url_data) != v:t_dict
    throw 'ProompterError configurations API URL is not string or dictionary'
  endif

  let l:url_data.pathname = '/api/show'
  let l:url = proompter#url#ToString(l:url_data)

  let l:result = {
        \   'url': l:url,
        \   'options': {
        \     'method': 'post',
        \     'headers': {
        \       'Host': l:configurations.channel.address,
        \       'Content-Type': 'application/json',
        \     },
        \     'body': {
        \       'name': l:name,
        \       'verbose': l:verbose,
        \     },
        \   },
        \ }

  return l:result
endfunction

""
" Return |dictionary| with `url` and request `options` defined.
"
" Parameter: {kwargs} with following properties~
" - `source` |string| model name to copy from API server's file system
" - `destination` |string| new model name based on `source`
" - `configurations` |ProompterConfigurations| default `g:proompter`, reads
"   `.channel.address`, and `.api.url`, without mutation
"
" Example: build payload data~ >
"   let payload_data = proompter#ollama#api#payload#Copy({
"         \   'source': 'codellama',
"         \   'destination': 'codellama-backup',
"         \   'configurations': g:proompter,
"         \ })
" <
"
" Example: result data structure~ >
"   {
"     'url': 'http://127.0.0.1:11434/api/copy',
"     'options': {
"       'method': 'post',
"       'headers': {
"         'Host': '127.0.0.1:41968',
"         'Content-Type': 'application/json',
"       },
"       'body': {
"         'source': 'codellama',
"         'destination': 'codellama-backup',
"       },
"     },
"   }
" <
"
" @throws ProompterError `Empty source`
" @throws ProompterError `Empty destination`
"
" See: functions~
" - |proompter#http#encode#Request|
"
" See: links~
" - https://github.com/ollama/ollama/blob/main/docs/api.md#copy-a-model
"
" See: tests~
" - tests/mocks/autoload_proompter_ollama_api_payload_Copy.vader
"
" @public
function! proompter#ollama#api#payload#Copy(kwargs = {}) abort
  let l:source = get(a:kwargs, 'source', '')
  if !len(l:source)
    throw 'ProompterError Empty source'
  endif

  let l:destination = get(a:kwargs, 'destination', '')
  if !len(l:destination)
    throw 'ProompterError Empty destination'
  endif

  let l:configurations = get(a:kwargs, 'configurations', g:proompter)

  let l:url_data = l:configurations.api.url
  if type(l:url_data) == v:t_string
    let l:url_data = proompter#url#FromString(l:url_data)
  elseif type(l:url_data) != v:t_dict
    throw 'ProompterError configurations API URL is not string or dictionary'
  endif

  let l:url_data.pathname = '/api/copy'
  let l:url = proompter#url#ToString(l:url_data)

  let l:result = {
        \   'url': l:url,
        \   'options': {
        \     'method': 'post',
        \     'headers': {
        \       'Host': l:configurations.channel.address,
        \       'Content-Type': 'application/json',
        \     },
        \     'body': {
        \       'source': l:source,
        \       'destination': l:destination,
        \     },
        \   },
        \ }

  return l:result
endfunction

""
" Return |dictionary| with `url` and request `options` defined.
"
" Parameter: {kwargs} with following properties~
" - `name` |string| of model to delete from API server's file system
" - `configurations` |ProompterConfigurations| default `g:proompter`, reads
"   `.channel.address`, and `.api.url`, without mutation
"
" Example: configurations~ >
"   let configurations = {
"         \   'select': {
"         \     'model_name': 'codellama',
"         \     'completion_endpoint': 'chat',
"         \   },
"         \   'api': {
"         \     'url': 'http://127.0.0.1:11434',
"         \   },
"         \   'channel': {
"         \     'address': '127.0.0.1:41968',
"         \   },
"         \ }
" <
"
" Example: build payload data~ >
"   let payload_data = proompter#ollama#api#payload#Delete({
"         \   'name': 'codellama',
"         \   'configurations': g:proompter,
"         \ })
" <
"
" Example: result data structure~ >
"   {
"     'url': 'http://127.0.0.1:11434/api/delete',
"     'options': {
"       'method': 'post',
"       'headers': {
"         'Host': '127.0.0.1:41968',
"         'Content-Type': 'application/json',
"       },
"       'body': {
"         'name': 'codellama',
"       },
"     },
"   }
" <
"
" @throws ProompterError `Empty name`
"
" See: functions~
" - |proompter#http#encode#Request|
"
" See: links~
" - https://github.com/ollama/ollama/blob/main/docs/api.md#delete-a-model
"
" See: tests~
" - tests/mocks/autoload_proompter_ollama_api_payload_Delete.vader
"
" @public
function! proompter#ollama#api#payload#Delete(kwargs = {}) abort
  let l:name = get(a:kwargs, 'name', '')
  if !len(l:name)
    throw 'ProompterError Empty name'
  endif

  let l:configurations = get(a:kwargs, 'configurations', g:proompter)

  let l:url_data = l:configurations.api.url
  if type(l:url_data) == v:t_string
    let l:url_data = proompter#url#FromString(l:url_data)
  elseif type(l:url_data) != v:t_dict
    throw 'ProompterError configurations API URL is not string or dictionary'
  endif

  let l:url_data.pathname = '/api/delete'
  let l:url = proompter#url#ToString(l:url_data)

  let l:result = {
        \   'url': l:url,
        \   'options': {
        \     'method': 'delete',
        \     'headers': {
        \       'Host': l:configurations.channel.address,
        \       'Content-Type': 'application/json',
        \     },
        \     'body': {
        \       'name': l:name,
        \     },
        \   },
        \ }

  return l:result
endfunction

""
" Return |dictionary| with `url` and request `options` defined.
"
" Parameter: {kwargs} with following properties~
" - `name` |string| of model to pull
" - `stream` |Boolean| default `v:true` enable/disable streaming of responses
" - `configurations` |ProompterConfigurations| default `g:proompter`, reads
"   `.channel.address`, and `.api.url`, without mutation
"
" Example: configurations~ >
"   let configurations = {
"         \   'select': {
"         \     'model_name': 'codellama',
"         \     'completion_endpoint': 'chat',
"         \   },
"         \   'api': {
"         \     'url': 'http://127.0.0.1:11434',
"         \   },
"         \   'channel': {
"         \     'address': '127.0.0.1:41968',
"         \   },
"         \ }
" <
"
" Example: build payload data~ >
"   let payload_data = proompter#ollama#api#payload#Pull({
"         \   'name': 'codellama',
"         \   'configurations': g:proompter,
"         \ })
" <
"
" Example: result data structure~ >
"   {
"     'url': 'http://127.0.0.1:11434/api/pull',
"     'options': {
"       'method': 'post',
"       'headers': {
"         'Host': '127.0.0.1:41968',
"         'Content-Type': 'application/json',
"       },
"       'body': {
"         'name': 'codellama',
"         'stream': v:true,
"       },
"     },
"   }
" <
"
" @throws ProompterError `Empty name`
"
" See: functions~
" - |proompter#http#encode#Request|
"
" See: links~
" - https://github.com/ollama/ollama/blob/main/docs/api.md#pull-a-model
"
" See: tests~
" - tests/mocks/autoload_proompter_ollama_api_payload_Pull.vader
"
" @public
function! proompter#ollama#api#payload#Pull(kwargs = {}) abort
  let l:name = get(a:kwargs, 'name', '')
  if !len(l:name)
    throw 'ProompterError Empty name'
  endif

  let l:configurations = get(a:kwargs, 'configurations', g:proompter)

  let l:url_data = l:configurations.api.url
  if type(l:url_data) == v:t_string
    let l:url_data = proompter#url#FromString(l:url_data)
  elseif type(l:url_data) != v:t_dict
    throw 'ProompterError configurations API URL is not string or dictionary'
  endif

  let l:url_data.pathname = '/api/pull'
  let l:url = proompter#url#ToString(l:url_data)

  let l:result = {
        \   'url': l:url,
        \   'options': {
        \     'method': 'post',
        \     'headers': {
        \       'Host': l:configurations.channel.address,
        \       'Content-Type': 'application/json',
        \     },
        \     'body': {
        \       'name': l:name,
        \       'stream': get(a:kwargs, 'stream', v:true),
        \     },
        \   },
        \ }

  return l:result
endfunction

""
" Return |dictionary| with `url` and request `options` defined.
"
" Parameter: {kwargs} with following properties~
" - `input` |list| or |string| to generate embeddings for
" - `truncate` |Boolean| default `v:true` returns error if `v:false` and
"   context length is exceeded
" - `options` |dictionary| `Modelfile` edits
" - `keep_alive` |string| how long model will stay loaded into memory
" - `configurations` |ProompterConfigurations| default `g:proompter`, reads
"   `.selected.model_name`, `.channel.address`, and `.api.url`, without
"   mutation
"
" Example: configurations~ >
"   let configurations = {
"         \   'select': {
"         \     'model_name': 'codellama',
"         \     'completion_endpoint': 'chat',
"         \   },
"         \   'api': {
"         \     'url': 'http://127.0.0.1:11434',
"         \   },
"         \   'channel': {
"         \     'address': '127.0.0.1:41968',
"         \   },
"         \ }
" <
"
" Example: build payload data~ >
"   let payload_data = proompter#ollama#api#payload#Embed({
"         \   'input': ['Why is vim so good?', 'Is EMACS better?'],
"         \   'configurations': g:proompter,
"         \ })
" <
"
" Example: result data structure~ >
"   {
"     'url': 'http://127.0.0.1:11434/api/embed',
"     'options': {
"       'method': 'post',
"       'headers': {
"         'Host': '127.0.0.1:41968',
"         'Content-Type': 'application/json',
"       },
"       'body': {
"         'model': 'codellama',
"         'input': ['Why is vim so good?', 'Is EMACS better?'],
"       },
"     },
"   }
" <
"
" @throws ProompterError `Empty input`
"
" See: functions~
" - |proompter#http#encode#Request|
"
" See: links~
" - https://github.com/ollama/ollama/blob/main/docs/api.md#generate-embeddings
" - https://github.com/ollama/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values
"
" See: tests~
" - tests/mocks/autoload_proompter_ollama_api_payload_Embed.vader
"
" @public
function! proompter#ollama#api#payload#Embed(kwargs = {}) abort
  let l:input = get(a:kwargs, 'input', '')
  if !len(l:input)
    throw 'ProompterError Empty input'
  endif

  let l:configurations = get(a:kwargs, 'configurations', g:proompter)

  let l:url_data = l:configurations.api.url
  if type(l:url_data) == v:t_string
    let l:url_data = proompter#url#FromString(l:url_data)
  elseif type(l:url_data) != v:t_dict
    throw 'ProompterError configurations API URL is not string or dictionary'
  endif

  let l:url_data.pathname = '/api/embed'
  let l:url = proompter#url#ToString(l:url_data)

  let l:result = {
        \   'url': l:url,
        \   'options': {
        \     'method': 'post',
        \     'headers': {
        \       'Host': l:configurations.channel.address,
        \       'Content-Type': 'application/json',
        \     },
        \     'body': {
        \       'model': l:configurations.select.model_name,
        \       'input': l:input,
        \     },
        \   },
        \ }

  let l:truncate = get(a:kwargs, 'truncate', v:null)
  if l:truncate != v:null && type(l:truncate) == v:t_bool
    let l:result.body['truncate'] = l:truncate
  endif

  let l:options = get(a:kwargs, 'options', v:null)
  if l:options != v:null && type(l:options) == v:t_dict
    let l:result.body['options'] = l:options
  endif

  let l:keep_alive = get(a:kwargs, 'keep_alive', v:null)
  if l:keep_alive != v:null && type(l:keep_alive) == v:t_string
    let l:result.body['keep_alive'] = l:keep_alive
  endif

  return l:result
endfunction

""
" Return |dictionary| with `url` and request `options` defined.
"
" Parameter: {kwargs} with following properties~
" - `configurations` |ProompterConfigurations| default `g:proompter`, reads
"   `.channel.address`, and `.api.url`, without mutation
"
" Example: configurations~ >
"   let configurations = {
"         \   'select': {
"         \     'model_name': 'codellama',
"         \     'completion_endpoint': 'chat',
"         \   },
"         \   'api': {
"         \     'url': 'http://127.0.0.1:11434',
"         \   },
"         \   'channel': {
"         \     'address': '127.0.0.1:41968',
"         \   },
"         \ }
" <
"
" Example: build payload data~ >
"   let payload_data = proompter#ollama#api#payload#Ps({
"         \   'configurations': g:proompter,
"         \ })
" <
"
" Example: result data structure~ >
"   {
"     'url': 'http://127.0.0.1:11434/api/ps',
"     'options': {
"       'method': 'get',
"       'headers': {
"         'Host': '127.0.0.1:41968',
"         'Content-Type': 'application/json',
"       },
"     },
"   }
" <
"
" See: functions~
" - |proompter#http#encode#Request|
"
" See: links~
" - https://github.com/ollama/ollama/blob/main/docs/api.md#list-running-models
"
" @public
function! proompter#ollama#api#payload#Ps(kwargs = {}) abort
  let l:configurations = get(a:kwargs, 'configurations', g:proompter)

  let l:url_data = l:configurations.api.url
  if type(l:url_data) == v:t_string
    let l:url_data = proompter#url#FromString(l:url_data)
  elseif type(l:url_data) != v:t_dict
    throw 'ProompterError configurations API URL is not string or dictionary'
  endif

  let l:url_data.pathname = '/api/ps'
  let l:url = proompter#url#ToString(l:url_data)

  let l:result = {
        \   'url': l:url,
        \   'options': {
        \     'method': 'get',
        \     'headers': {
        \       'Host': l:configurations.channel.address,
        \       'Content-Type': 'application/json',
        \     },
        \   },
        \ }

  return l:result
endfunction

""
" Return |dictionary| with `url` and request `options` defined.
"
" Parameter: {kwargs} with following properties~
" - `prompt` |string| to generate embeddings for
" - `options` |dictionary| `Modelfile` edits
" - `keep_alive` |string| how long model will stay loaded into memory
" - `configurations` |ProompterConfigurations| default `g:proompter`, reads
"   `.selected.model_name`, `.channel.address`, and `.api.url`, without
"   mutation
"
" Example: configurations~ >
"   let configurations = {
"         \   'select': {
"         \     'model_name': 'codellama',
"         \     'completion_endpoint': 'chat',
"         \   },
"         \   'api': {
"         \     'url': 'http://127.0.0.1:11434',
"         \   },
"         \   'channel': {
"         \     'address': '127.0.0.1:41968',
"         \   },
"         \   'models': {
"         \     'codellama': {
"         \       'parameters': {
"         \         'raw': v:false,
"         \         'stream': v:true,
"         \       },
"         \     },
"         \   },
"         \ }
" <
"
" Example: build payload data~ >
"   let payload_data = proompter#ollama#api#payload#Embeddings({
"         \   'prompt': 'Here is an article about llamas...',
"         \   'configurations': g:proompter,
"         \ })
" <
"
" Example: result data structure~ >
"   {
"     'url': 'http://127.0.0.1:11434/api/embeddings',
"     'options': {
"       'method': 'post',
"       'headers': {
"         'Host': '127.0.0.1:41968',
"         'Content-Type': 'application/json',
"       },
"       'body': {
"         'model': 'codellama',
"         'prompt': 'Here is an article about llamas...',
"       },
"     },
"   }
" <
"
" @throws ProompterError `Empty prompt`
"
" See: functions~
" - |proompter#http#encode#Request|
"
" See: links~
" - https://github.com/ollama/ollama/blob/main/docs/api.md#generate-embeddings
" - https://github.com/ollama/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values
"
" See: tests~
" - tests/mocks/autoload_proompter_ollama_api_payload_Embeddings.vader
"
" @public
function! proompter#ollama#api#payload#Embeddings(kwargs = {}) abort
  let l:prompt = get(a:kwargs, 'prompt', '')
  if !len(l:prompt)
    throw 'ProompterError Empty prompt'
  endif

  let l:configurations = get(a:kwargs, 'configurations', g:proompter)

  let l:url_data = l:configurations.api.url
  if type(l:url_data) == v:t_string
    let l:url_data = proompter#url#FromString(l:url_data)
  elseif type(l:url_data) != v:t_dict
    throw 'ProompterError configurations API URL is not string or dictionary'
  endif

  let l:url_data.pathname = '/api/embeddings'
  let l:url = proompter#url#ToString(l:url_data)

  let l:result = {
        \   'url': l:url,
        \   'options': {
        \     'method': 'post',
        \     'headers': {
        \       'Host': l:configurations.channel.address,
        \       'Content-Type': 'application/json',
        \     },
        \     'body': {
        \       'model': l:configurations.select.model_name,
        \       'prompt': l:prompt,
        \     },
        \   },
        \ }

  let l:options = get(a:kwargs, 'options', v:null)
  if l:options != v:null && type(l:options) == v:t_dict
    let l:result.body['options'] = l:options
  endif

  let l:keep_alive = get(a:kwargs, 'keep_alive', v:null)
  if l:keep_alive != v:null && type(l:keep_alive) == v:t_string
    let l:result.body['keep_alive'] = l:keep_alive
  endif

  return l:result
endfunction

" vim: expandtab
