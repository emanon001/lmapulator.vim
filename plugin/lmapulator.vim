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

if !has('langmap')
  echoerr 'lmapulator does not work, when there is no "langmap" feature.'
  finish
elseif !has('modify_fname')
  echoerr 'lmapulator does not work, when there is no "modify_fname" feature.'
  finish
elseif exists('g:loaded_lmapulator')
  finish
endif

let s:save_cpoptions = &cpoptions
set cpoptions&vim




" Options {{{1

function! s:set_default_option(name, value)
  if !exists('g:lmapulator#' . a:name)
    let g:lmapulator#{a:name} = a:value
  endif
endfunction

call s:set_default_option('enable_at_startup', 0)
call s:set_default_option('source_keyboard_layout', 'qwerty')
call s:set_default_option('destination_keyboard_layout', '')




" Commands {{{1

command! -nargs=1 -complete=customlist,lmapulator#complete_destination_keyboard_layout LmapulatorSwitch
      \ call lmapulator#switch(<q-args>)

command! -nargs=1 -complete=customlist,lmapulator#complete_source_keyboard_layout LmapulatorSwitchSource
      \ call lmapulator#set_source_keyboard_layout(<q-args>)

command! -nargs=0 LmapulatorEnable
      \ call lmapulator#enable()

command! -nargs=0 LmapulatorDisable
      \ call lmapulator#disable()

command! -nargs=1 -complete=file LmapulatorLoad
      \ call lmapulator#load(fnamemodify(<q-args>, ':p'))

command! -nargs=0 LmapulatorReload
      \ call lmapulator#reload()




" Autocommands {{{1

if g:lmapulator#enable_at_startup
  augroup lmapulator
    autocmd!
    autocmd VimEnter * call lmapulator#enable()
  augroup END
endif




" Epilogue {{{1

let g:loaded_lmapulator = 1

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions




" __END__ {{{1
" vim: foldmethod=marker
