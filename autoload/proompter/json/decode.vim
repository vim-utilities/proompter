#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter



""
" Extract dictionary/object from `data`, starting at `index`, and return
" |dictionary| with `value` and `consumed` defined.
function! proompter#json#decode#Dictionary(data, index) abort
  let l:result = { 'value': {}, 'consumed': v:null }

  let l:slice_end = a:index

  let l:key = v:null

  let l:depth = 0

  let l:data_length = len(a:data)
  while l:slice_end < l:data_length
    let l:character = a:data[l:slice_end]

    if l:character == '{'
      if l:key == v:null
        let l:depth += 1
      else
        let l:dictionary_data = proompter#json#decode#Dictionary(a:data, l:slice_end)
        let l:result.value[l:key] = l:dictionary_data.value
        let l:key = v:null
        let l:slice_end += l:dictionary_data.consumed - 1
      endif
    elseif l:character == '}'
      let l:depth -= 1
      if l:depth == 0
        let l:slice_end += 1
        break
      endif
    elseif l:character == '"'
      let l:string_data = proompter#json#decode#String(a:data, l:slice_end)
      if l:key == v:null
        let l:key = l:string_data.value
      else
        let l:result.value[l:key] = l:string_data.value
        let l:key = v:null
      endif
      let l:slice_end += l:string_data.consumed - 1
    elseif l:character =~ '\v(\d|-)'
      if l:key == v:null
        throw 'ProompterError expected `"` but got `' . l:character . '` at `' . l:slice_end . '`'
      endif
      let l:number_data = proompter#json#decode#Number(a:data, l:slice_end)
      let l:result.value[l:key] = l:number_data.value
      let l:key = v:null
      let l:slice_end += l:number_data.consumed - 1
    elseif l:character =~ '\v(n|t|f)'
      if l:key == v:null
        throw 'ProompterError expected `"` but got `' . l:character . '` at `' . l:slice_end . '`'
      endif
      let l:literal_data = proompter#json#decode#Literal(a:data, l:slice_end)
      let l:result.value[l:key] = l:literal_data.value
      let l:key = v:null
      let l:slice_end += l:literal_data.consumed - 1
    elseif l:character == ':'
      if l:key == v:null
        throw 'ProompterError expected `"` but got `' . l:character . '` at `' . l:slice_end . '`'
      endif
    elseif l:character == ','
      if l:key != v:null
        throw 'ProompterError expected `"`, `}`, or `]` but got `' . l:character . '` at `' . l:slice_end . '`'
      endif
    elseif l:character == '['
      if l:key == v:null
        throw 'ProompterError expected `"`, `}`, or `]` but got `' . l:character . '` at `' . l:slice_end . '`'
      endif
      let l:list_data = proompter#json#decode#List(a:data, l:slice_end)
      let l:result.value[l:key] = l:list_data.value
      let l:key = v:null
      let l:slice_end += l:list_data.consumed - 1
    elseif l:character !~ '\v(\s|\r|\n)+'
      throw 'ProompterError unexpected character `' . l:character . '` at `' . l:slice_end . '`' 
    endif

    let l:slice_end += 1
  endwhile

  if l:depth > 0
    throw 'ProompterError expected `}` but got `' . a:data[l:slice_end] . '` at `' . l:slice_end . '`'
  endif

  let l:result.consumed = l:slice_end - a:index
  return l:result
endfunction

""
" Extract an array/list of values from `data`, starting at `index`, and return
" |dictionary| with `value` and `consumed` defined.
function! proompter#json#decode#List(data, index) abort
  let l:result = { 'value': [], 'consumed': v:null }

  let l:slice_end = a:index

  let l:key = v:null

  let l:depth = 0

  let l:data_length = len(a:data)
  while l:slice_end < l:data_length
    let l:character = a:data[l:slice_end]

    if l:character == '['
      if l:depth == 0
        let l:depth += 1
      else
        let l:list_data = proompter#json#decode#List(a:data, l:slice_end)
        call add(l:result.value, l:list_data.value)
        let l:slice_end += l:list_data.consumed - 1
      endif
    elseif l:character == ']'
      let l:depth -= 1
      if l:depth == 0
        let l:slice_end += 1
        break
      endif
    elseif l:character == '{'
      let l:dictionary_data = proompter#json#decode#Dictionary(a:data, l:slice_end)
      call add(l:result.value, l:dictionary_data.value)
      let l:slice_end += l:dictionary_data.consumed - 1
    elseif l:character == '"'
      let l:string_data = proompter#json#decode#String(a:data, l:slice_end)
      call add(l:result.value, l:string_data.value)
      let l:slice_end += l:string_data.consumed - 1
    elseif l:character =~ '\v(\d|-)'
      let l:number_data = proompter#json#decode#Number(a:data, l:slice_end)
      call add(l:result.value, l:number_data.value)
      let l:slice_end += l:number_data.consumed - 1
    elseif l:character =~ '\v(n|t|f)'
      let l:literal_data = proompter#json#decode#Literal(a:data, l:slice_end)
      call add(l:result.value, l:literal_data.value)
      let l:slice_end += l:literal_data.consumed - 1
    elseif l:character !~ '\v(\s|\r|\n|,)+'
      throw 'ProompterError unexpected character `' . l:character . '` at `' . l:slice_end . '`' 
    endif

    let l:slice_end += 1
  endwhile

  if l:depth > 0
    throw 'ProompterError expected `]` but got `' . l:character . '` at `' . (l:slice_end - 1) . '`'
  endif

  let l:result.consumed = l:slice_end - a:index
  return l:result
endfunction

""
" Extract literal `null`, `true`, or `false` from `data`, starting at `index`,
" surrounded by double-quotes and return |dictionary| with `value` and
" `consumed` defined.
function! proompter#json#decode#Literal(data, index) abort
  let l:result = { 'value': v:null, 'consumed': v:null }

  let l:slice = { 'start': a:index, 'end': v:null, 'value': v:null }
  let l:character = a:data[a:index]

  if l:character == 'n'
    let l:slice.end = l:slice.start + len('null') - 1
  elseif l:character == 't'
    let l:slice.end = l:slice.start + len('true') - 1
  elseif l:character == 'f'
    let l:slice.end = l:slice.start + len('false') - 1
  endif

  if l:slice.end != v:null
    let l:slice.value = a:data[l:slice.start:l:slice.end]
    if l:slice.value == 'null'
      let l:result.consumed = 4
    elseif l:slice.value == 'true'
      let l:result.consumed = 4
      let l:result.value = v:true
    elseif l:slice.value == 'false'
      let l:result.consumed = 5
      let l:result.value = v:false
    endif
  endif

  if l:result.consumed != v:null
    return l:result
  endif

  throw 'ProompterError failed to parse literal expected `null`, `true`, or `false` but got -> `' . l:slice.value . '`'
endfunction

""
" Extract a float or integer from `data`, starting at `index`, and return
" |dictionary| with `value` and `consumed` defined.
function! proompter#json#decode#Number(data, index) abort
  let l:result = { 'value': v:null, 'consumed': v:null }

  let l:slice_end = a:index

  let l:found = {
        \   'sign': v:false,
        \   'integer': v:false,
        \   'fractional': v:false,
        \ }

  let l:data_length = len(a:data)
  while l:slice_end < l:data_length
    let l:character = a:data[l:slice_end]

    if l:slice_end == a:index
      if l:character == '-'
        let l:found.sign = v:true
      elseif l:character =~ '\d'
        let l:found.integer = v:true
      else
        throw 'ProompterError expected `-` or `\d` but got -> `' . l:character . '`'
      endif
    elseif l:character == '.'
      if l:found.integer
        let l:found.float = v:true
      else
        throw 'ProompterError expected `\d` but got -> `' . l:character . '`'
      endif
    elseif l:character =~ '\d'
      if !l:found.integer
        let l:found.integer = v:true
      endif
    elseif l:slice_end > a:index
      break
    endif

    let l:slice_end += 1
  endwhile

  if !l:found.integer
    throw 'ProompterError failed to parse number between -> ' . a:index . ' and ' . l:slice_end
  endif

  let l:result.value = a:data[a:index:l:slice_end-1]
  let l:result.consumed = l:slice_end - a:index
  return l:result
endfunction

""
" Extract a key or value from `data`, starting at `index`, surrounded by
" double-quotes and return |dictionary| with `value` and `consumed` defined.
function! proompter#json#decode#String(data, index) abort
  let l:result = { 'value': v:null, 'consumed': v:null }

  let l:slice_start = a:index
  let l:slice_end = a:index

  let l:inside_string = v:false
  let l:escape_count = 0

  let l:data_length = len(a:data)
  while l:slice_end < l:data_length
    let l:character = a:data[l:slice_end]

    if l:inside_string
      if l:character == '\'
        let l:escape_count += 1
      else
        if l:character == '"'
          if l:escape_count == 0 || l:escape_count % 2 == 0
            let l:bad_idea = '{"value":' . a:data[l:slice_start-1:l:slice_end] . '}'
            let l:result.value = json_decode(l:bad_idea).value
            let l:result.consumed = l:slice_end - a:index + 1
            return l:result
          endif
        endif
        let l:escape_count = 0
      endif
    elseif l:character == '"'
      let l:inside_string = v:true
      let l:slice_start = l:slice_end + 1
    endif

    let l:slice_end += 1
  endwhile

  throw 'ProompterError failed to parse string between -> ' . a:index . ' and ' . l:slice_end
endfunction

" vim: expandtab
