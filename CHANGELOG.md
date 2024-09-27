# Changelog
[heading__changelog]: #changelog


All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][] and this project adheres to
[Semantic Versioning][].


## [Unreleased]
[heading__unreleased]: #unreleased


- [ ] Vim command and motion integration examples
  - [ ] Command to send selected text to LLM, maybe with additional context?
  - [ ] Motion to generate documentation for visual selection?
- [ ] Quick prompt processing canceling from Vim
  - [ ] function for sending cancel request
- [ ] Proxy traffic between Vim `channel` and Ollama API
  - [ ] releases listening port
  - [ ] tested with system-level SystemD
   > Note; the `Wants`, `Requires`, and other bindings to `ollama.service` may need additional testing

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

