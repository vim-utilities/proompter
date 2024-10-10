#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
" Attempt to parse image paths from input string
"
" Parameter: {define__configurations} configurations
" Parameter: {define__proompter_state} state - Dictionary
"
" TODO: thoroughly test that bad paths cannot be injected to traverse above
" current working directory
function! proompter#callback#prompt#EncodeImagesFromInput(input, configurations = g:proompter, state = g:proompter_state) abort
  let l:paths = map(matchstrlist([a:input], '\v\./(\w+(/\w+)?)\.(jpg|png)>'), { _index, matched ->
        \   matched.text
        \ })

  return proompter#callback#prompt#EncodeImagesFromFilePaths(l:paths, a:configurations, a:state)
endfunction

""
" Base 64 encodes image file paths and returns list
"
" Parameter: {list} paths - String list of paths to image files
" Parameter: {define__configurations} configurations
" Parameter: {define__proompter_state} state - Dictionary
"
" See: {docs} :help readfile()
function! proompter#callback#prompt#EncodeImagesFromFilePaths(paths, _configurations = g:proompter, _state = g:proompter_state) abort
  let l:encoded_images = []

  for l:path in a:paths
    if !filereadable(l:path)
      echow 'Cannot read image ->' l:path
      continue
    endif

    call add(l:encoded_images, proompter#base64#EncodeFile(l:path))
  endfor

  return l:encoded_images
endfunction

" vim: expandtab
