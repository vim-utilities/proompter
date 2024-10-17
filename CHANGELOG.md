# Changelog
[heading__changelog]: #changelog


All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][] and this project adheres to
[Semantic Versioning][].


## [Unreleased]
[heading__unreleased]: #unreleased


- [ ] Support function/tools request calls from/to LLMs
- [ ] Proxy traffic between Vim `channel` and Ollama API
  - [ ] releases listening port
   > Note; `kill -SIGINT <PID>` works for interactive sessions, but doesn't
   > when backgrounded within Vader test runner script?!
  - [ ] tested with system-level SystemD
   > Note; the `Wants`, `Requires`, and other bindings to `ollama.service` may
   > need additional testing
- [ ] Allow [python-hot-reload][] of `scripts/proompter-channel-proxy.py`?
- [ ] Refactor code and configurations to allow connections to other LLM APIs?
  - [vllm][]

[python-hot-reload]: https://stackoverflow.com/questions/29960634/reload-the-currently-running-python-script
[vllm]: https://docs.vllm.ai/en/latest/getting_started/quickstart.html

______


## [0.0.7] - 2024-10-17


- [X] Build documentation from doc-comments
- [X] HTTP Response parser handles non-`200` status codes


______


## [0.0.6] - 2024-10-13


- [X] Passing mock tests for `autoload/proompter.vim`
  - [X] `proompter#SendPromptToGenerate`
  - [X] `proompter#SendPrompt`
  - [X] `proompter#SendHighlightedText`
  - [X] `proompter#Cancel`
  - [X] `proompter#Load`
  - [X] `proompter#Unload`
- [X] `doc/proompter.txt` is correct and up-to-date?
- [X] Add `pre-commit` hook to help mitigate known committing bugs


______


## [0.0.5] - 2024-10-10


- [X] Fix `g:proompter_state.messages` save/load to/from JSON file
- [X] Add and fix `base64` wrappers, plus track related unit tests
- [X] Parse image input/outputs
  - [X] Client can send images for encoding as Base64 by file/directory path
  - [X] LLM can reply with Base64 images for configured callback to handle
  - [X] Experimental support for saving generated images to `/tmp` directory
   > Note; due to limited support for image generation this by default is only
   > active when using `proompter#callback#channel#StreamToBuffer` function.
   >
   > Additionally, the `/api/chat` end-point context callback will re-submit
   > past images, but for now the `/api/generate` context callback does not.


______


## [0.0.4] - 2024-10-08


- [X] Fix JSON parser!!!
- [X] Optimize and normalize proxy streaming behavior for real and mock classes


______


## [0.0.3] - 2024-10-07


- [X] Enable prompt callbacks defaults, and per-model per-endpoint overrides!
  - `g:proompter.api.prompt_callbacks.chat`
  - _`g:proompter.models.<model_name>.prompt_callbacks.chat`_
  - `g:proompter.api.prompt_callbacks.generate`
  - _`g:proompter.models.<model_name>.prompt_callbacks.generate`_
   > :warning: This means anyone upgrading from tagged versions prior to
   > `v0.0.3` will need to nest preexisting callback configurations!
   >
   > If using the default `api.url` endpoint path of `/api/generate`, then
   > encapsulate your `prompt_callbacks` key/value pares within a;
   > `'generate': {}` dictionary.
   >
   > Note; this may not be the last time such changes are made!  If for example
   > this plugin eventually supports more than Ollama API, then additional
   > name-space alterations will probably be required.
- [X] Passing unit tests!
  - [X] `autoload/proompter/callback/channel.vim`
  - [X] `autoload/proompter/callback/prompt/chat.vim`
  - [X] `autoload/proompter/callback/prompt/generate.vim`
  - [X] `autoload/proompter/channel.vim`
  - [X] `autoload/proompter/format.vim`
  - [X] `autoload/proompter/parse.vim`


______


## [0.0.2] - 2024-10-03


- [X] Format input/output to buffer functions better
  - [X] Prompt selected text from code files should be bound by backticks
- [X] Vim command and motion integration examples
  - [X] Command to send selected text to LLM, maybe with additional context!
  - [X] Map examples to send selection to LLM, and quick cancel too
- [X] Quick prompt processing canceling from Vim
  - [X] Function for sending cancel request
  - [X] Command example to call cancel function
- [X] Make parsing of HTTP responses resilient to funkiness
  - [X] Parse headers into Vim dictionary
  - [X] Parse bodiless headers
  - [X] Parse headless body
  - [X] Parse body as dictionary list, where dictionaries may touch or be
    separated by combo of; carriage-return with newline, just a newline, and/or
    some amount of spaces X-P
- [X] Chat history is preserved and properly re-submitted for each prompt
  - [X] Enable saving message history to file
  - [X] Enable loading message history from file
  - [X] Client correctly uses [chat-request-with-history][] feature

[chat-request-with-history]: https://github.com/ollama/ollama/blob/main/docs/api.md#chat-request-with-history


______


## [0.0.1] - 2024-09-26


- [ ] Proxy traffic between Vim `channel` and Ollama API
  - [X] returns full response
  - [X] returns streaming responses, line-by-line/token-by-token
  - [X] tested with user-level SystemD
- [X] Vim client can write prompts and responses to temp buffer
  - [x] new-lines are honored when writing prompts
  - [X] new-lines are honored when writing response
   > Note; formatting between headings and content is kinda inconsistent

### Added


- Start maintaining versions and a changelog.


[Keep a Changelog]: https://keepachangelog.com/en/1.0.0/
[Semantic Versioning]: https://semver.org/spec/v2.0.0.html

