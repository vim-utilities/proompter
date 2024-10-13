#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter
"
" Note: pipes instead of process substitution is necessary to make GitHub
" Actions play nice with tests, however, for those using the Linux Subsystem
" on Windows or Cygwin there may be a performance hit :-(

""
" Encode string to Base64 via `system` call
"
" Parameter: {string} `string` Input to pipe to `base64` command
"
" Throws: 'No string value' if input is zero length
" Throws: following format string when `v:shell_error` is non-zero
"
" ```
" Failed command: printf "%s" '<string>' | base64 --wrap=0
"   Exit status: <number>
" ```
"
" Example: input
"
" ```vim
" echo proompter#base64#EncodeString('Howdy reader!')
" ```
"
" Example: result
"
" ```
" SG93ZHkgcmVhZGVyIQ==
" ```
"
" See: {docs} :help system()
" See: {docs} :help shellescape()
" See: {docs} :help v:shell_error
" See: {tests} tests/units/autoload_proompter_base64.vader
function! proompter#base64#EncodeString(string) abort
  if !len(a:string)
    throw 'No string value'
  endif

  let l:string = shellescape(a:string)
  let l:command = 'printf "%s" ' . l:string . ' | base64 --wrap=0'

  let l:result = system(l:command)
  if v:shell_error
    throw "Failed command: " . l:command . "\n\tExit status: " . v:shell_error
  endif
  return l:result
endfunction

""
" Decode string from Base64 via `system` call
"
" Parameter: {string} `string` Input to pipe to `base64` command
"
" Throws: 'No string value' if input is zero length
" Throws: following format string when `v:shell_error` is non-zero
"
" ```
" Failed command: printf "%s" '<string>' | base64 --decode
"   Exit status: <number>
" ```
"
" Example: input
"
" ```vim
" echo proompter#base64#EncodeString('SG93ZHkgcmVhZGVyIQ==')
" ```
"
" Example: result
"
" ```
" Howdy reader!
" ```
"
" See: {docs} :help system()
" See: {docs} :help shellescape()
" See: {docs} :help v:shell_error
" See: {tests} tests/units/autoload_proompter_base64.vader
function! proompter#base64#DecodeString(string) abort
  if !len(a:string)
    throw 'No string value'
  endif

  let l:string = shellescape(a:string)
  let l:command = 'printf "%s" ' . l:string . ' | base64 --decode'

  let l:result = system(l:command)
  if v:shell_error
    throw "Failed command: " . l:command . "\n\tExit status: " . v:shell_error
  endif
  return l:result
endfunction

""
" Encode file at `path` via `system` call to `base64`
"
" Parameter: {string} `path` Input to file for `base64` to encode
"
" Throws: 'No path value' if input is zero length
" Throws: 'Cannot read file -> <path>' when file cannot be read
" Throws: following format string when `v:shell_error` is non-zero
"
" ```
" Failed command: printf "%s" '<string>' | base64 --decode
"   Exit status: <number>
" ```
"
" Example: create and pass input file
"
" ```vim
" let path = '/tmp/test.txt'
" call writefile(['Howdy reader!'], path)
" echo proompter#base64#EncodeFile(path)
" ```
"
" Example: result
"
" ```
" SG93ZHkgcmVhZGVyIQo=
" ```
"
" See: {docs} :help filereadable()
" See: {docs} :help system()
" See: {docs} :help shellescape()
" See: {docs} :help v:shell_error
" See: {tests} tests/units/autoload_proompter_base64.vader
function! proompter#base64#EncodeFile(path) abort
  if !len(a:path)
    throw 'No path value'
  endif

  if !filereadable(a:path)
    throw 'Cannot read file -> ' . a:path
  endif

  let l:path = shellescape(a:path)
  let l:command = 'base64 --wrap=0 ' . l:path

  let l:result = system(l:command)
  if v:shell_error
    throw "Failed command: " . l:command . "\n\tExit status: " . v:shell_error
  endif
  return l:result
endfunction

""
" Decode `string` to file at `path` via `system` call to `base64`
"
" Parameter: {string} `string` Encoded string to pipe to `base64`
" Parameter: {string} `path` File for `base64` to save decoded results to
" Parameter: {string} `flags` TODO
"
" Throws: 'No string value' if input is zero length
" Throws: 'No path value' if input is zero length
" Throws: 'File already exists -> <path>' when file cannot be overwritten
" Throws: following format string when `v:shell_error` is non-zero
"
" ```
" Failed command: printf "%s" '<string>' | base64 --decode > <path>
"   Exit status: <number>
" ```
"
" Example: create and pass input file
"
" ```vim
" let path = '/tmp/decode.txt'
" call proompter#base64#DecodeToFile('SG93ZHkgcmVhZGVyIQo=', path)
" !cat /tmp/decode.txt
" ```
"
" Example: result
"
" ```
" Howdy reader!
" ```
"
" See: {docs} :help filereadable()
" See: {docs} :help system()
" See: {docs} :help shellescape()
" See: {docs} :help v:shell_error
" See: {tests} tests/units/autoload_proompter_base64.vader
" TODO: implement `flags` parser to have similar behavior to `writefile`
"
" See: {tests} tests/units/autoload_proompter_base64.vader
function! proompter#base64#DecodeToFile(string, path, flags = '') abort
  if !len(a:string)
    throw 'No string value'
  endif

  if !len(a:path)
    throw 'No path value'
  endif

  if filereadable(a:path)
    throw 'File already exists -> ' . a:path
  endif

  let l:path = shellescape(a:path)
  let l:string = shellescape(a:string)
  let l:command = 'printf "%s" ' . l:string . ' | base64 --decode > ' . l:path

  let l:result = system(l:command)
  if v:shell_error
    throw "Failed command: " . l:command . "\n\tExit status: " . v:shell_error
  endif
  return l:result
endfunction

" vim: expandtab
