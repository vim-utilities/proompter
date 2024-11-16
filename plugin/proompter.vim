#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter
" Version: 0.0.6
"
" TODO: consider the following resources to improve plugin distribution
"
" - :help pi_getscript.txt

""
" @section License
"
" This project is licensed based on use-case
"
" Commercial and/or proprietary use~
"
" If a project is **either** commercial or (`||`) proprietary, then please
" contact the author for pricing and licensing options to make use of code and/or
" features from this repository.
"
" Non-commercial and FOSS use~
"
" If a project is **both** non-commercial and (`&&`) published with a license
" compatible with AGPL-3.0, then it may utilize code from this repository under
" the following terms. >
"   Proxy traffic between Vim channel requests and Ollama LLM API
"   Copyright (C) S0AndS0
"
"   This program is free software: you can redistribute it and/or modify
"   it under the terms of the GNU Affero General Public License as published
"   by the Free Software Foundation, version 3 of the License.
"
"   This program is distributed in the hope that it will be useful,
"   but WITHOUT ANY WARRANTY; without even the implied warranty of
"   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"   GNU Affero General Public License for more details.
"
"   You should have received a copy of the GNU Affero General Public License
"   along with this program.  If not, see <https://www.gnu.org/licenses/>.
" <

if exists('g:proompter__loaded') || v:version < 700
  finish
endif
let g:proompter__loaded = 1

""
" @setting g:proompter
" @dict ProompterConfigurations
" ProompterConfigurations that may be overwritten
"
"
" - {ProompterConfigurationsSelect} `select`
" - {ProompterConfigurationsAPI} `api`
" - {ProompterConfigurationsChannel} `channel`
" - {ProompterConfigurationsModels} `models`
"
" Default: `g:proompter`~ >
"   let s:defaults = {
"         \   'select': {
"         \     'model_name': 'codellama',
"         \     'completion_endpoint': 'chat',
"         \   },
"         \   'api': {
"         \     'url': 'http://127.0.0.1:11434',
"         \     'prompt_callbacks': {
"         \       'chat': {},
"         \       'generate': {},
"         \     },
"         \   },
"         \   'channel': {
"         \     'address': '127.0.0.1:11435',
"         \     'options': {
"         \       'mode': 'raw',
"         \       'callback': v:null,
"         \     },
"         \   },
"         \   'models': {
"         \     'codellama': {
"         \       'prompt_callbacks': {
"         \         'chat': {},
"         \         'generate': {},
"         \       },
"         \       'data': {
"         \         'raw': v:false,
"         \         'stream': v:true,
"         \       },
"         \     },
"         \   },
"         \ }
" <

let s:defaults = {
      \   'select': {
      \     'model_name': 'codellama',
      \     'completion_endpoint': 'chat',
      \   },
      \   'api': {
      \     'url': 'http://127.0.0.1:11434',
      \     'prompt_callbacks': {
      \       'chat': {},
      \       'generate': {},
      \     },
      \   },
      \   'channel': {
      \     'address': '127.0.0.1:11435',
      \     'options': {
      \       'mode': 'raw',
      \       'callback': v:null,
      \     },
      \   },
      \   'models': {
      \     'codellama': {
      \       'prompt_callbacks': {
      \         'chat': {},
      \         'generate': {},
      \       },
      \       'data': {
      \         'raw': v:false,
      \         'stream': v:true,
      \       },
      \     },
      \   },
      \ }

""
" @dict ProompterConfigurationsSelect
" Example: `g:proompter.select.model_name`~ >
"   let g:proompter = {
"         \   'select': {
"         \     'model_name': 'codellama',
"         \     'completion_endpoint': 'chat',
"         \   },
"         \ }
" <
" {string} `select.model_name` Name used for API requests as well as optional
" key name into {ProompterConfigurationsModels}
"
" {string} `select.completion_endpoint` API end point used for prompting,
" currently `chat` or `generate` are supported for Ollama

""
" @dict ProompterConfigurationsAPI
" Example: `g:proompter.api`~ >
"   let g:proompter = {
"         \   'select': {
"         \     'model_name': 'codellama',
"         \     'completion_endpoint': 'generate',
"         \   },
"         \   'api': {
"         \     'url': 'http://127.0.0.1:11434',
"         \     'prompt_callbacks': {
"         \       'chat': {},
"         \       'generate': {},
"         \     },
"         \   },
"         \ }
" <
" {string} `api.url` Currently this is how you may select API endpoints for
" `chat` or `generate` features when prompting LLMs
"
" {ProompterConfigurationsAPIPromptCallbacks} `api.prompt_callbacks` Provides default
" callbacks for endpoints if not defined in {ProompterConfigurationsModels}
"

""
" @dict ProompterConfigurationsAPIPromptCallbacks
"
" Example: `g:proompter.api.prompt_callbacks.generate`~ >
"   let g:proompter = {
"         \   'select': {
"         \     'model_name': 'codellama',
"         \     'completion_endpoint': 'generate',
"         \   },
"         \   'api': {
"         \     'url': 'http://127.0.0.1:11434',
"         \     'prompt_callbacks': {
"         \       'chat': {
"         \         'preamble': function('ChatPreamble'),
"         \         'context': function('ChatContext'),
"         \         'input': function('ChatInput'),
"         \         'images': function('ChatImages'),
"         \         'post': function('ChatPost'),
"         \       },
"         \       'generate': {
"         \         'preamble': function('GeneratePreamble'),
"         \         'context': function('GenerateContext'),
"         \         'input': function('GenerateInput'),
"         \         'post': function('GeneratePost'),
"         \       },
"         \     },
"         \   },
"         \ }
" <
"
" - {ProompterConfigurationsAPIPromptCallbacksChat} `chat` Collection of
"   callback function references to use when
"   `g:proompter.select.completion_endpoint` is `chat`
" - {ProompterConfigurationsAPIPromptCallbacksGenerate} `generate` Collection
"   of callback function references to use when
"   `g:proompter.select.completion_endpoint` is `generate`

""
" @dict ProompterConfigurationsAPIPromptCallbacksChat
"
" Example: `g:proompter.api.prompt_callbacks.chat`~ >
"   let g:proompter = {
"         \   'api': {
"         \     'url': 'http://127.0.0.1:11434',
"         \     'prompt_callbacks': {
"         \       'chat': {
"         \         'preamble': function('ChatPreamble'),
"         \         'context': function('ChatContext'),
"         \         'input': function('ChatInput'),
"         \         'images': function('ChatImages'),
"         \         'post': function('ChatPost'),
"         \       },
"         \     },
"         \   },
"         \ }
" <
"
" {Funcref} `preamble` receives {ProompterConfigurations} and {ProompterState} and should
" produce a message {dictionary} similar to >
"   {
"     "role": "system",
"     "content": "You are a JavaScript expert!"
"   }
" <
"
" {Funcref} `context` receives {ProompterConfigurations} and {ProompterState} and should produce
" a {dictionary} list similar to >
"   [
"     {
"       "role": "user",
"       "content": "Tell me in one sentence why Vim is the best.",
"     },
"     {
"       "role": "assistant",
"       "content": "Vim is the best!",
"     },
"   ]
" <
"
" {Funcref} `input` receives {string}, {ProompterConfigurations}, and {ProompterState} and
" should produce a message {dictionary} similar to >
"   {
"     "role": "user",
"     "content": "Okay...  Does this look normal?",
"   }
" <
"
" {Funcref} `images` receives {string}, {ProompterConfigurations}, and {ProompterState} and
" should produce a Base64 encoded {string} {list} of similar to >
"   [
"     "deadbeef...",
"     "boba7ea...",
"   ]
" <
"
" {Funcref} `post` receives {dictionary} of previous callback results,
" {ProompterConfigurations}, and {ProompterState} and should produce a {dictionary} {list}
" similar to >
"   [
"     {
"       "role": "system",
"       "content": "You are a JavaScript expert!"
"     },
"     {
"       "role": "user",
"       "content": "Tell me in one sentence why Vim is the best.",
"     },
"     {
"       "role": "assistant",
"       "content": "Vim is the best!",
"     },
"     {
"       "role": "user",
"       "content": "Okay...  Does this look normal?",
"       "images": [
"         "deadbeef...",
"         "boba7ea...",
"       ],
"     }
"   ]
" <

""
" @dict ProompterConfigurationsAPIPromptCallbacksGenerate
"
" Example: `g:proompter.api.prompt_callbacks.generate`~ >
"   let g:proompter = {
"         \   'select': {
"         \     'model_name': 'codellama',
"         \     'completion_endpoint': 'generate',
"         \   },
"         \   'api': {
"         \     'url': 'http://127.0.0.1:11434',
"         \     'prompt_callbacks': {
"         \       'generate': {
"         \         'preamble': function('GeneratePreamble'),
"         \         'context': function('GenerateContext'),
"         \         'input': function('GenerateInput'),
"         \         'post': function('GeneratePost'),
"         \       },
"         \     },
"         \   },
"         \ }
" <
"
" {Funcref} `preamble` receives {ProompterConfigurations} and {ProompterState} and should
" produce a {string} similar to >
"   <<SYS>>You are a JavaScript expert!<</SYS>>
" <
"
" {Funcref} `context` receives {ProompterConfigurations} and {ProompterState} and should produce
" a {string} similar to >
"   [INST]Tell me in one sentence why Vim is the best.[/INST]
"   [INST]Vim is the best![/INST]
" <
"
" {Funcref} `input` receives {string}, {ProompterConfigurations}, and {ProompterState} and
" should produce a {string} similar to >
"   Okay...  Does this look normal?
" <
"
" {Funcref} `post` receives {dictionary} of previous callback results,
" {ProompterConfigurations}, and {ProompterState} and should produce a {string} similar to >
"   <<SYS>>You are a JavaScript expert!<</SYS>>
"   [INST]Tell me in one sentence why Vim is the best.[/INST]
"   [INST]Vim is the best![/INST]
"   Okay...  Does this look normal?
" <

""
" @dict ProompterConfigurationsChannel
"
" Example: `g:proompter.channel`~ >
"   let g:proompter = {
"         \   'channel': {
"         \     'address': '127.0.0.1:11435',
"         \     'options': {
"         \       'mode': 'raw',
"         \       'callback': v:null,
"         \     },
"         \   },
"         \ }
" <
" {string} `address` See: |channel-address| this should match the address and
" port that `scripts/proompter-channel-proxy.py` service listens on for
" connections from Vim
"
" {ProompterConfigurationsChannelOptions} `options` See: |channel-open-options| Passed
" to `ch_open` when creating new proxied connection to API

""
" @dict ProompterConfigurationsChannelOptions
" Passed to `ch_open` when creating new proxied connection to API
"
" Example: `g:proompter.channel.options`~ >
"   let g:proompter = {
"         \   'channel': {
"         \     'options': {
"         \       'mode': 'raw',
"         \       'callback': v:null,
"         \     },
"         \   },
"         \ }
" <
"
" {string} `mode` See: |channel-mode| default, and recommended, value is
" `'raw'` as this allows for more flexibility with how request and response
" data may be formatted
"
" {Funcref} `callback` See: |channel-callback|

""
" @dict ProompterConfigurationsModels
"
" 
" Example: `g:proompter.models`~ >
"   let g:proompter = {
"         \   'models': {
"         \     'codellama': {
"         \       'prompt_callbacks': {
"         \         'chat': {},
"         \         'generate': {},
"         \       },
"         \       'data': {
"         \         'raw': v:false,
"         \         'stream': v:true,
"         \       },
"         \     },
"         \   },
"         \ }
" <
" {dictionary} with key/value pares of;
"
" - {string} `key` that `g:proompter.select.model_name` may point at
" - {ProompterConfigurationsModel} `value` that is used for defining custom callbacks
"   and data to be passed to model

""
" @dict ProompterConfigurationsModel
"
" {ProompterConfigurationsAPIPromptCallbacks} `prompt_callbacks` override defaults
" defined in `g:proompter.api.prompt_callbacks` for a given model.  Check
" @dict(ProompterConfigurationsAPIPromptCallbacks) for additional details and examples.
"
" {ProompterConfigurationsModelData} `data` parameter defaults merged with prompt

""
" @dict ProompterConfigurationsModelData
"
" Example: `g:proompter.models['model_name'].data`~ >
"   let g:proompter = {
"         \   'models': {
"         \     'codellama': {
"         \       'data': {
"         \         'raw': v:false,
"         \         'stream': v:true,
"         \       },
"         \     },
"         \   },
"         \ }
" <
"
" See: documentation from Ollama API for up-to-date info
" - https://github.com/ollama/ollama/blob/main/docs/api.md#parameters
" - https://github.com/ollama/ollama/blob/main/docs/api.md#parameters-1
"
" /api/chat or /api/generate~
"
" {string} `model` automatically set from `g:proompter.select.model_name` by
" plugin functions
"
" {string} `format`, only value of "json" is supported as of 2024-10-15
"
" {dictionary} `options` additional parameters that modify `Modelfile`
" configurations, see following links for details;
" - https://github.com/ollama/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values
"
" {boolean} `stream` default value is `v:true`, but tests show that `v:false`
" should be supported.
"
" {boolean} `raw` default and recommended value is `v:true`
"
" {string} `keep_alive` default, according to documentation, is `5m` (five
" minuets) for how long model will remain in memory between calls.
"
" /api/chat~
"
" {list} `messages` {PromptChatMessage} list that
" @function(proompter#callback#prompt#chat#Context) re-sends to model to
" simulate memory between prompts
"
" {list} `tools` TODO
"
" /api/generate~
"
" {string} `system`
" TODO refactor @function(proompter#callback#prompt#generate#Post), and
" related code to match behaviors of
" @function(proompter#callback#prompt#chat#Post) and
" @function(proompter#callback#prompt#chat#Preamble)
"
" {string} `prompt` set by @function(proompter#callback#prompt#generate#Post)
"
" {string} `suffix` TODO
"
" {list} `images` TODO
"
" {list} `context` TODO refactor
" @function(proompter#callback#prompt#chat#Context) and
" @function(proompter#callback#prompt#generate#Post)

""
" @dict PromptChatMessage
"
" {string} `role` the role of the message, either "system", "user",
" "assistant", or "tool"
"
" {string} `content` the content of the message
" {list} `images` (optional) a list of images to include in the message (for
" multimodal models such as "llava")
"
" {dictionary} `tool_calls` (optional) a list of tools the model wants to use

""
" @setting g:proompter_state
" @dict ProompterState
"
" Example: `g:proompter_state`~ >
"   {
"     "channel": v:null,
"     "messages": [
"       {
"         "role": "system",
"         "content": "You an expert with javascript",
"       },
"       {
"         "role": "user",
"         "content": "Tell me in one sentence Vim is the best text editor.",
"       },
"       {
"         "role": "assistant",
"         "content": "Vim is the best!",
"       },
"     ],
"   }
" <
"
" This dictionary stores current `channel` used to communicate with API proxy,
" and list of `messages` data sent to/from LLM(s)
"
" {channel} `channel` Last used or current channel that is in use, or `v:null`
" if no channel has been assigned within current running Vim session.
"
" See: following built-in functions for more details about channels
" - @function(ch_open)
" - @function(ch_info)
"
" {list} `messages` {dictionary} list of messages sent to, and received from,
" Ollama API
"
" See: official Ollama API documentation
" - https://github.com/ollama/ollama/blob/main/docs/api.md

let g:proompter_state = {
      \  'channel': v:null,
      \  'messages': [],
      \ }

""
" Merge global customization with defaults to `g:proompter`
" See: {docs} :help fnamemodify()
" See: {docs} :help readfile()
" See: {docs} :help json_decode()
if exists('g:proompter')
  if type(g:proompter) == v:t_string && fnamemodify(g:proompter, ':e') == 'json'
    let g:proompter = json_decode(join(readfile(g:proompter), ''))
  endif

  if type(g:proompter) == v:t_dict
    let g:proompter = proompter#lib#DictMerge(s:defaults, g:proompter)
  else
    let g:proompter = deepcopy(s:defaults)
  endif
else
  let g:proompter = deepcopy(s:defaults)
endif

" vim: expandtab
