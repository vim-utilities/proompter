# Changelog
[heading__changelog]: #changelog


All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][] and this project adheres to
[Semantic Versioning][].


## [Unreleased]
[heading__unreleased]: #unreleased


- [ ] `doc/proompter.txt` is correct and up-to-date?
- [ ] Proxy traffic between Vim `channel` and Ollama API
  - [ ] releases listening port
  - [ ] tested with system-level SystemD
   > Note; the `Wants`, `Requires`, and other bindings to `ollama.service` may need additional testing
- [ ] Parse image input/outputs
  - [ ] Client can send images for encoding as Base64 by file/directory path
  - [ ] LLM can reply with Base64 images for configured callback to handle


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

