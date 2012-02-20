" Manipulate the 'langmap' option.
" Version: 0.0.1
" Author:  emanon001 <emanon001@gmail.com>
" License: DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2 {{{
"     This program is free software. It comes without any warranty, to
"     the extent permitted by applicable law. You can redistribute it
"     and/or modify it under the terms of the Do What The Fuck You Want
"     To Public License, Version 2, as published by Sam Hocevar. See
"     http://sam.zoy.org/wtfpl/COPYING for more details.
" }}}

" Prologue {{{1

scriptencoding utf-8

let s:save_cpoptions = &cpoptions
set cpoptions&vim








" Variables {{{1
" Definition of constant. {{{2

let s:TRUE = 1
let s:FALSE = !s:TRUE
let s:PLUGIN_NAME = expand('<sfile>:t:r')

lockvar! s:TRUE s:FALSE s:PLUGIN_NAME




" Definition of a variable. {{{2

let s:lmapulator = {}








" Interface {{{1

function! lmapulator#switch(keyboard_layout) " {{{2
  if !s:lmapulator.defined_source_keyboard_layout_p(
        \ s:lmapulator.get_current_source_keyboard_layout())
    call s:print_error('Setting the source keyboard layout "' . 
          \            s:lmapulator.get_current_source_keyboard_layout() .
          \            '" is not defined.')
    return
  endif
  if !s:lmapulator.defined_destination_keyboard_layout_p(
        \ s:lmapulator.get_current_source_keyboard_layout(), a:keyboard_layout)
    call s:print_error('Setting the switch keyboard layout "' . 
          \            s:lmapulator.get_current_source_keyboard_layout() . 
          \            '" to "' . a:keyboard_layout . '" is not defined.')
    return
  endif

  if !s:lmapulator.enable_p()
    call s:lmapulator.set_saved_langmap(&langmap)
  endif

  let langmap = s:lmapulator.get_langmap(s:lmapulator.get_current_source_keyboard_layout(), 
        \                                a:keyboard_layout)
  let &langmap = langmap

  call s:lmapulator.set_current_destination_keyboard_layout(a:keyboard_layout)

  call s:lmapulator.enable()
endfunction

function! lmapulator#enable() " {{{2
  if s:lmapulator.enable_p()
    return
  endif

  if !s:lmapulator.defined_current_source_keyboard_layout_p()
    call s:print_error('Setting the source keyboard layout "' . 
          \ s:lmapulator.get_current_source_keyboard_layout() . '" is not defined.')
    return
  endif
  if !s:lmapulator.defined_current_destination_keyboard_layout_p()
    call s:print_error('Setting the switch keyboard layout "' . 
          \ s:lmapulator.get_current_source_keyboard_layout() . 
          \ '" to "' . s:lmapulator.get_current_destination_keyboard_layout() . '" is not defined.')
    return
  endif

  call s:lmapulator.set_saved_langmap(&langmap)
  let langmap = s:lmapulator.get_langmap(s:lmapulator.get_current_source_keyboard_layout(), 
        \                                s:lmapulator.get_current_destination_keyboard_layout())
  let &langmap = langmap

  call s:lmapulator.enable()
endfunction

function! lmapulator#disable() " {{{2
  if s:lmapulator.enable_p()
    let &langmap = s:lmapulator.get_saved_langmap()
  endif
  call s:lmapulator.disable()
endfunction

function! lmapulator#set_source_keyboard_layout(keyboard_layout) " {{{2
  return s:lmapulator.set_current_source_keyboard_layout(a:keyboard_layout)
endfunction

function! lmapulator#source_keyboard_layout() " {{{2
  return s:lmapulator.get_current_source_keyboard_layout()
endfunction

function! lmapulator#destination_keyboard_layout() " {{{2
  return s:lmapulator.get_current_destination_keyboard_layout()
endfunction

function! lmapulator#enable_p() " {{{2
  return s:lmapulator.enable_p()
endfunction

function! lmapulator#load(file_path) " {{{2
  return s:lmapulator.load_langmap_file(fnamemodify(a:file_path, ':p'))
endfunction

function! lmapulator#reload() " {{{2
  return s:lmapulator.load_langmap_files()
endfunction









" Core {{{1
" Load langmap files. {{{2

function! s:lmapulator.load_langmap_files() " {{{3
  let langmap_source_paths = split(globpath(&runtimepath, 'langmap/*'), '\n')
  for s_path in langmap_source_paths
    let source_keyboard_layout = fnamemodify(s_path, ':p:h:t')
    for d_path in split(glob(fnamemodify(s_path, ':p') . '*.vim'), '\n')
      call self.load_langmap_file(fnamemodify(d_path, ':p'), source_keyboard_layout)
    endfor
  endfor
endfunction

function! s:lmapulator.load_langmap_file(file_path, ...) " {{{3
  " Note: langmap directory structure
  " langmap
  "   └{source_keyboard_layout}
  "       └{destination_keyboard_layout}.vim
  let source_keyboard_layout = exists('a:1') ? a:1 : fnamemodify(a:file_path, ':p:h:t')
  if !self.defined_source_keyboard_layout_p(source_keyboard_layout)
    " Init source keyboard layout config.
    call self.set_source_keyboard_layout_config(source_keyboard_layout, {})
  endif

  let langmap_config = self.file_to_config(a:file_path)
  let destination_keyboard_layout = fnamemodify(a:file_path, ':t:r')
  " TODO: To enable the override.
  if !self.defined_destination_keyboard_layout_p(source_keyboard_layout, destination_keyboard_layout)
    call self.set_destination_keyboard_layout_config(source_keyboard_layout, destination_keyboard_layout, langmap_config)
  endif
endfunction

function! s:lmapulator.file_to_config(file_path) " {{{3
  " Note: langmap file format
  "  - It will become a comment line if double quote is described at the head of the sentence.
  "  - The map of a character is described as follows.
  "    1. {source_char}{white_space}{destination_char}
  "    2. {source_char_list}{white_space}{destination_char_list}
  "  - Map can be described by only one per line.
  " example:
  "  " comment line
  "  a   A
  "  bcd BCD

  let lines = readfile(a:file_path)
  " Remove comment line.
  call filter(lines, 'v:val !~ "^\\s*\""')
  " Remove blank line.
  call filter(lines, 'v:val !~ "^\\s*$"')
  " Each map to convert the format 'langmap' option.
  let langmap = ''
  let is_first = s:TRUE
  for l in lines
    let _ = matchlist(l, '^\s*\(\S\+\)\%(\s\+\)\(\S\+\).*$')
    let is_char_pair = strchars(_[1]) == 1 ? s:TRUE : s:FALSE
    let delimiter = is_first ? '' : ','

    " Escape special characters.(;,\"|)
    let src = s:escape_langmap(_[1])
    let dest = s:escape_langmap(_[2])

    if is_char_pair
      " Pair of characters.
      let langmap .= delimiter . src . dest
    else
      " Pair of character list.
      let langmap .= delimiter . src . ';' . dest
    endif
    let is_first = s:FALSE
  endfor

  let config = {'langmap': langmap}
  return config
endfunction




" Variable operation of lmapulator. {{{2

function! s:lmapulator._get_value(property, ...) " {{{3
  let ctx = exists('a:1') ? a:1 : self._variables_
  return get(ctx, a:property)
endfunction

function! s:lmapulator._set_value(property, value, ...) " {{{3
  let ctx = exists('a:1') ? a:1 : self._variables_
  let ctx[a:property] = a:value
endfunction

function! s:lmapulator._define_accessor(type, property, ...) " {{{3
  let optional_args = exists('a:1') ? copy(a:1) : {}
  let optional_args_default_values = {
        \  'is_hide': s:FALSE,
        \  'is_pred': s:FALSE,
        \  'args': '',
        \  'access_property': '',
        \  'ctx': ''
        \ }
  let options = s:union_dictionary(optional_args, optional_args_default_values)

  if a:type ==# 'accessor'
    call self.__define_getter(a:property, options)
    call self.__define_setter(a:property, options)
  elseif a:type ==# 'getter'
    call self.__define_getter(a:property, options)
  elseif a:type ==# 'setter'
    call self.__define_setter(a:property, options)
  endif
endfunction

function! s:lmapulator.__define_getter(property, options) " {{{3
  execute printf("function! s:lmapulator.%s%s(%s)\n
        \   return self._get_value(%s%s)\n
        \ endfunction",
        \
        \ a:options.is_hide ? '_' : '',
        \ a:options.is_pred ? substitute(a:property, '^is_\(.*\)$', '\1_p', '') : 'get_' . a:property,
        \ !empty(a:options.args) ? join(a:options.args, ', ') : '',
        \ a:options.access_property != '' ? a:options.access_property :  "'" . a:property . "'",
        \ a:options.ctx != '' ? ', ' . a:options.ctx : '')
endfunction

function! s:lmapulator.__define_setter(property, options) " {{{3
  execute printf("function! s:lmapulator.%sset_%s(%svalue)\n
        \   return self._set_value(%sa:value%s)\n
        \ endfunction",
        \
        \ a:options.is_hide ? '_' : '',
        \ a:options.is_pred ? substitute(a:property, '^is_\(.*\)$', '\1', '') : a:property,
        \ !empty(a:options.args) ? join(a:options.args, ', ') . ', ' : '',
        \ a:options.access_property != '' ? a:options.access_property . ', ' :  "'" . a:property . "', ",
        \ a:options.ctx != '' ? ', ' . a:options.ctx : '')
endfunction

function! s:lmapulator.defined_source_keyboard_layout_p(keyboard_layout) " {{{3
  return has_key(self.get_langmap_config_table(), a:keyboard_layout)
endfunction

function! s:lmapulator.defined_destination_keyboard_layout_p(source_keyboard_layout, dest_keyboard_layout) " {{{3
  return has_key(self.get_source_keyboard_layout_config(a:source_keyboard_layout), a:dest_keyboard_layout)
endfunction

function! s:lmapulator.defined_current_source_keyboard_layout_p() " {{{3
  return self.defined_source_keyboard_layout_p(self.get_current_source_keyboard_layout())
endfunction

function! s:lmapulator.defined_current_destination_keyboard_layout_p() " {{{3
  return self.defined_destination_keyboard_layout_p(self.get_current_source_keyboard_layout(), 
        \                                           self.get_current_destination_keyboard_layout())
endfunction

function! s:lmapulator.enable() " {{{3
  call self.set_enable(s:TRUE)
endfunction

function! s:lmapulator.disable() " {{{3
  call self.set_enable(s:FALSE)
endfunction








" Misc {{{1

function! s:print_error(message) " {{{2
  let messages = [s:PLUGIN_NAME . ': The error occurred.']

  if type(a:message) == type([])
    call expand(messages, a:message)
  else
    call add(messages, a:message)
  endif

  for _ in messages
    echohl WarningMsg | echomsg _ | echohl None
  endfor
endfunction

function! s:union_dictionary(dict, add_dict) " {{{2
  let ret = copy(a:dict)
  for key in keys(a:add_dict)
    if !has_key(ret, key)
      let ret[key] = get(a:add_dict, key)
    endif
  endfor
  return ret
endfunction

function! s:escape_langmap(str) " {{{2
  let ret = substitute(a:str, '\', '\\\\', 'g')
  return substitute(ret, '\([,;"|]\)', '\\\1', 'g')
endfunction

function! lmapulator#complete_source_keyboard_layout(arg_lead, cmd_line, cursor_pos) " {{{2
  return filter(keys(s:lmapulator.get_langmap_config_table()), 'v:key =~ a:arg_lead')
endfunction

function! lmapulator#complete_destination_keyboard_layout(arg_lead, cmd_line, cursor_pos) " {{{2
  return filter(keys(s:lmapulator.get_source_keyboard_layout_config(
        \              s:lmapulator.get_current_source_keyboard_layout())), 'v:key =~ a:arg_lead')
endfunction








" Init {{{1

function! s:lmapulator.__init__() " {{{2
  call self.__init_variables__()
  call self.__init_accessor__()

  " TODO: Lazy load.
  call self.load_langmap_files()
endfunction

function! s:lmapulator.__init_variables__() " {{{2
  let self._variables_ = {
        \  'langmap_config_table': {},
        \  'current_source_keyboard_layout': g:lmapulator#source_keyboard_layout,
        \  'current_destination_keyboard_layout': g:lmapulator#destination_keyboard_layout,
        \  'saved_langmap': '',
        \  'is_enable': s:FALSE
        \ }
endfunction

function! s:lmapulator.__init_accessor__() " {{{2
  " langmap_config_table
  call self._define_accessor('getter', 'langmap_config_table')
  " - source_keyboard_layout_config
  call self._define_accessor('accessor', 'source_keyboard_layout_config',
        \                     {'args': ['keyboard_layout'],
        \                      'access_property': 'a:keyboard_layout',
        \                      'ctx': 'self.get_langmap_config_table()'})
  " -- destination_keyboard_layout_config
  call self._define_accessor('accessor', 'destination_keyboard_layout_config',
        \                     {'args': ['source_keyboard_layout', 'dest_keyboard_layout'],
        \                      'access_property': 'a:dest_keyboard_layout',
        \                      'ctx': 'self.get_source_keyboard_layout_config(a:source_keyboard_layout)'})
  " --- langmap
  call self._define_accessor('getter', 'langmap',
        \                     {'args': ['source_keyboard_layout', 'dest_keyboard_layout'],
        \                      'ctx': 'self.get_destination_keyboard_layout_config(a:source_keyboard_layout, a:dest_keyboard_layout)'})

  " current_source_keyboard_layout
  call self._define_accessor('accessor', 'current_source_keyboard_layout')

  " current_destination_keyboard_layout
  call self._define_accessor('accessor', 'current_destination_keyboard_layout')

  " is_enable
  call self._define_accessor('accessor', 'is_enable', {'is_pred': s:TRUE})

  " saved_langmap
  call self._define_accessor('accessor', 'saved_langmap')
endfunction




" Call the initialization function. {{{2

call s:lmapulator.__init__()









" Epilogue {{{1

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions








" __END__ {{{1
" vim: foldmethod=marker
