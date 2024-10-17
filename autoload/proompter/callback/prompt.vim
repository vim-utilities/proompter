#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
" Attempt to parse image paths from input string
"
" Parameters:~
" - {input} |string| to parse for image paths
" - {configurations} |ProompterConfigurations| default `g:proompter`
" - {state} |ProompterState| default `g:proompter_state`
"
" TODO: thoroughly test that bad paths cannot be injected to traverse above
" current working directory
"
" @public
function! proompter#callback#prompt#EncodeImagesFromInput(input, configurations = g:proompter, state = g:proompter_state) abort
  let l:paths = map(matchstrlist([a:input], '\v\./(\w+(/\w+)?)\.(jpg|png)>'), { _index, matched ->
        \   matched.text
        \ })

  return proompter#callback#prompt#EncodeImagesFromFilePaths(l:paths, a:configurations, a:state)
endfunction

""
" Base 64 encodes image file paths and returns list
"
" Parameters:~
" - {paths} String |list| of paths to image files
" - {configurations} |ProompterConfigurations| default `g:proompter` currently
"   ignored
" - {state} |ProompterState| default `g:proompter_state` currently ignored
"
" See: documentation~
" - |readfile()|
"
" See: tests~
" - tests/units/autoload_proompter_callback_prompt.vader
"
" @public
function! proompter#callback#prompt#EncodeImagesFromFilePaths(paths, _configurations = g:proompter, _state = g:proompter_state) abort
  let l:encoded_images = []
  let l:skipped_paths = []

  for l:path in a:paths
    if !filereadable(l:path)
      call add(l:skipped_paths, l:path)
      continue
    endif

    call add(l:encoded_images, proompter#base64#EncodeFile(l:path))
  endfor

  if len(l:skipped_paths)
    echoe 'l:skipped_paths ->' l:skipped_paths
  endif

  return l:encoded_images
endfunction

" vim: expandtab
