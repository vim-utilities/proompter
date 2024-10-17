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
" Parameter: {input} |string| to pipe to `base64` command
"
" @throws ProompterError `Empty input value` if input is zero length
" @throws ProompterError with following format if `v:shell_error` is non-zero
" >
"   Failed command: printf "%s" '_string_' | base64 --wrap=0
"     Exit status: _number_
" <
"
" Example: input~ >
"   echo proompter#base64#EncodeString('Howdy reader!')
" <
"
" Example: result~ >
"   SG93ZHkgcmVhZGVyIQ==
" <
"
" See: documentation~
" - :help system()
" - :help shellescape()
" - :help v:shell_error
"
" See: tests~
" - tests/units/autoload_proompter_base64.vader
" 
" @public
function! proompter#base64#EncodeString(input) abort
  if !len(a:input)
    throw 'ProompterError Empty input value'
  endif

  let l:input = shellescape(a:input)
  let l:command = 'printf "%s" ' . l:input . ' | base64 --wrap=0'

  let l:result = system(l:command)
  if v:shell_error
    throw "ProompterError Failed command: " . l:command . "\n\tExit status: " . v:shell_error
  endif
  return l:result
endfunction

""
" Decode string from Base64 via `system` call
"
" Parameters:~
" - {input} |string| Input to pipe to `base64` command
"
" @throws ProompterError `Empty input value` if input is zero length
" @throws ProompterError with following format if `v:shell_error` is non-zero
" >
"   Failed command: printf "%s" '_string_' | base64 --decode
"     Exit status: _number_
" <
"
" Example: input~ >
"   echo proompter#base64#EncodeString('SG93ZHkgcmVhZGVyIQ==')
" <
" Example: result~ >
"   Howdy reader!
" <
"
" See: documentation~
" - |system()|
" - |shellescape()|
" - |v:shell_error|
"
" See: tests~
" - tests/units/autoload_proompter_base64.vader
"
" @public
function! proompter#base64#DecodeString(input) abort
  if !len(a:input)
    throw 'ProompterError Empty input value'
  endif

  let l:input = shellescape(a:input)
  let l:command = 'printf "%s" ' . l:input . ' | base64 --decode'

  let l:result = system(l:command)
  if v:shell_error
    throw "ProompterError Failed command: " . l:command . "\n\tExit status: " . v:shell_error
  endif
  return l:result
endfunction

""
" Encode file at `path` via `system` call to `base64`
"
" Parameters:~
" - {path} |string| input to file for `base64` to encode
"
" @throws ProompterError `Empty path value` if input is zero length
" @throws ProompterError `Cannot read file -> <path>` when file cannot be read
" @throws ProompterError with following format if `v:shell_error` is non-zero
" >
"   Failed command: printf "%s" '<string>' | base64 --decode
"     Exit status: <number>
" <
"
" Example: create and pass input file~ >
"   let path = '/tmp/test.txt'
"   call writefile(['Howdy reader!'], path)
"   echo proompter#base64#EncodeFile(path)
" <
"
" Example: result~ >
"   SG93ZHkgcmVhZGVyIQo=
" <
"
" See: documentation~
" - |filereadable()|
" - |system()|
" - |shellescape()|
" - |v:shell_error|
"
" See: tests~
" - tests/units/autoload_proompter_base64.vader
"
" @public
function! proompter#base64#EncodeFile(path) abort
  if !len(a:path)
    throw 'ProompterError Empty path value'
  endif

  if !filereadable(a:path)
    throw 'ProompterError Cannot read file -> ' . a:path
  endif

  let l:path = shellescape(a:path)
  let l:command = 'base64 --wrap=0 ' . l:path

  let l:result = system(l:command)
  if v:shell_error
    throw "ProompterError Failed command: " . l:command . "\n\tExit status: " . v:shell_error
  endif
  return l:result
endfunction

""
" Decode `string` to file at `path` via `system` call to `base64`
"
" Parameters:~
" - {string} |string| encoded to pipe to `base64`
" - {path} |string| file path for `base64` to save decoded results to
" - {flags} |string| default `""` TODO implement `flags` parser to have
"   similar behavior to `writefile`
"
" @throws ProompterError `Empty string value` if input is zero length
" @throws ProompterError `Empty path value` if path is zero length
" @throws ProompterError `File already exists -> <path>` when file cannot be
" overwritten
" @throws ProompterError with following format if `v:shell_error` is non-zero
" >
"   Failed command: printf "%s" '<string>' | base64 --decode > <path>
"     Exit status: <number>
" <
"
" Example: create and pass input file~ >
"   let path = '/tmp/decode.txt'
"   call proompter#base64#DecodeToFile('SG93ZHkgcmVhZGVyIQo=', path)
"   !cat /tmp/decode.txt
" <
"
" Example: result~ >
"   Howdy reader!
" <
"
" See: documentation~
" - |filereadable()|
" - |system()|
" - |shellescape()|
" - |v:shell_error|
"
" See: tests~
" - tests/units/autoload_proompter_base64.vader
"
" @public
function! proompter#base64#DecodeToFile(string, path, flags = '') abort
  if !len(a:string)
    throw 'ProompterError Empty string value'
  endif

  if !len(a:path)
    throw 'ProompterError Empty path value'
  endif

  if filereadable(a:path)
    throw 'ProompterError File already exists -> ' . a:path
  endif

  let l:path = shellescape(a:path)
  let l:string = shellescape(a:string)
  let l:command = 'printf "%s" ' . l:string . ' | base64 --decode > ' . l:path

  let l:result = system(l:command)
  if v:shell_error
    throw "ProompterError Failed command: " . l:command . "\n\tExit status: " . v:shell_error
  endif
  return l:result
endfunction

" vim: expandtab
