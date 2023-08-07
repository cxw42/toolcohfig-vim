" plugin/toolconfig.vim: ToolConfig native Vimscript plugin file
" Copyright (c) 2011-2023 EditorConfig Team, including Christopher White
" All rights reserved.
"
" Redistribution and use in source and binary forms, with or without
" modification, are permitted provided that the following conditions are met:
"
" 1. Redistributions of source code must retain the above copyright notice,
"    this list of conditions and the following disclaimer.
" 2. Redistributions in binary form must reproduce the above copyright notice,
"    this list of conditions and the following disclaimer in the documentation
"    and/or other materials provided with the distribution.
"
" THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
" IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
" ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
" LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
" CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
" SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
" INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
" CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
" ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
" POSSIBILITY OF SUCH DAMAGE.
"

" check for Vim versions and duplicate script loading.
if v:version < 700 || exists("g:loaded_ToolConfig")
    finish
endif
let g:loaded_ToolConfig = 1

let s:saved_cpo = &cpo
set cpo&vim

" variables {{{1

" Make sure the globals all exist
if !exists('g:ToolConfig_exec_path')
    let g:ToolConfig_exec_path = ''
endif

if !exists('g:ToolConfig_verbose')
    let g:ToolConfig_verbose = 0
endif

if !exists('g:ToolConfig_preserve_formatoptions')
    let g:ToolConfig_preserve_formatoptions = 0
endif

if !exists('g:ToolConfig_max_line_indicator')
    let g:ToolConfig_max_line_indicator = 'line'
endif

if !exists('g:ToolConfig_exclude_patterns')
    let g:ToolConfig_exclude_patterns = []
endif

if !exists('g:ToolConfig_disable_rules')
    let g:ToolConfig_disable_rules = []
endif

if !exists('g:ToolConfig_enable_for_new_buf')
    let g:ToolConfig_enable_for_new_buf = 0
endif

if !exists('g:ToolConfig_softtabstop_space')
    let g:ToolConfig_softtabstop_space = 1
endif

if !exists('g:ToolConfig_softtabstop_tab')
    let g:ToolConfig_softtabstop_tab = 1
endif

" Copy some of the globals into script variables --- changes to these
" globals won't affect the plugin until the plugin is reloaded.
if exists('g:ToolConfig_core_mode') && !empty(g:ToolConfig_core_mode)
    let s:toolconfig_core_mode = g:ToolConfig_core_mode
else
    let s:toolconfig_core_mode = ''
endif

if exists('g:ToolConfig_exec_path') && !empty(g:ToolConfig_exec_path)
    let s:toolconfig_exec_path = g:ToolConfig_exec_path
else
    let s:toolconfig_exec_path = ''
endif

let s:initialized = 0

" }}}1

" Mode initialization functions {{{1

function! s:InitializePythonModule()
" Initialize python_module mode
    try
        py3 import toolconfig_core
        return 0
    endtry

    echo "Could not initialize python module"
    return 1
endfunction

function! s:InitializeExternalCommand()
" Initialize external_command mode

    if empty(s:toolconfig_exec_path)
        echo 'Please specify a g:ToolConfig_exec_path'
        return 1
    endif

    if g:ToolConfig_verbose
        echo 'Checking for external command ' . s:toolconfig_exec_path . ' ...'
    endif

    if !executable(s:toolconfig_exec_path)
        echo 'File ' . s:toolconfig_exec_path . ' is not executable.'
        return 1
    endif

    return 0
endfunction
" }}}1

function! s:Initialize() " Initialize the plugin.  {{{1
    " Returns truthy on error, falsy on success.

    if empty(s:toolconfig_core_mode)
        let s:toolconfig_core_mode = 'python_module'   " Default core choice
    endif

    if s:toolconfig_core_mode ==? 'python_module'
        if s:InitializePythonModule()
            echohl WarningMsg
            echo 'ToolConfig: Failed to initialize external_command mode.'
            echohl None
       return 1
        endif

    elseif s:toolconfig_core_mode ==? 'external_command'
        if s:InitializeExternalCommand()
            echohl WarningMsg
            echo 'ToolConfig: Failed to initialize external_command mode.'
            echohl None
            return 1
        endif
    else
        echohl ErrorMsg
        echo "ToolConfig: I don't know how to use mode " . s:toolconfig_core_mode
        echohl None
        return 1
    endif

    let s:initialized = 1
    return 0
endfunction " }}}1

function! s:UseConfigFiles(from_autocmd) abort " Apply config to the current buffer {{{1
    " from_autocmd is truthy if called from an autocmd, falsy otherwise.

    " Get the properties of the buffer we are working on
    if a:from_autocmd
        let l:bufnr = str2nr(expand('<abuf>'))
        let l:buffer_name = expand('<afile>:p')
        let l:buffer_path = expand('<afile>:p:h')
    else
        let l:bufnr = bufnr('%')
        let l:buffer_name = expand('%:p')
        let l:buffer_path = expand('%:p:h')
    endif
    call setbufvar(l:bufnr, 'toolconfig_tried', 1)

    " Only process normal buffers (do not treat help files as '.txt' files)
    " When starting Vim with a directory, the buftype might not yet be set:
    " Therefore, also check if buffer_name is a directory.
    if index(['', 'acwrite'], &buftype) == -1 || isdirectory(l:buffer_name)
        return
    endif

    if empty(l:buffer_name)
        if g:ToolConfig_enable_for_new_buf
            let l:buffer_name = getcwd() . "/."
        else
            if g:ToolConfig_verbose
                echo 'Skipping ToolConfig for unnamed buffer'
            endif
            return
        endif
    endif

    if getbufvar(l:bufnr, 'ToolConfig_disable', 0)
        if g:ToolConfig_verbose
            echo 'ToolConfig disabled --- skipping buffer "' . l:buffer_name . '"'
        endif
        return
    endif

    " Ignore specific patterns
    for pattern in g:ToolConfig_exclude_patterns
        if l:buffer_name =~ pattern
            if g:ToolConfig_verbose
                echo 'Skipping ToolConfig for buffer "' . l:buffer_name .
                    \ '" based on pattern "' . pattern . '"'
            endif
            return
        endif
    endfor

    if !s:initialized
        if s:Initialize()
            return
        endif
    endif

    if g:ToolConfig_verbose
        echo 'Applying ToolConfig ' . s:toolconfig_core_mode .
            \ ' on file "' . l:buffer_name . '"'
    endif

    if s:toolconfig_core_mode ==? 'external_command'
        call s:UseConfigFiles_ExternalCommand(l:bufnr, l:buffer_name)
        call setbufvar(l:bufnr, 'toolconfig_applied', 1)
    else
        echohl Error |
                    \ echo "Unknown ToolConfig Core: " .
                    \ s:toolconfig_core_mode |
                    \ echohl None
    endif
endfunction " }}}1

" Custom commands, and autoloading {{{1

" Autocommands, and function to enable/disable the plugin {{{2
function! s:ToolConfigEnable(should_enable)
    augroup toolconfig
        autocmd!
        if a:should_enable
            autocmd BufNewFile,BufReadPost,BufFilePost * call s:UseConfigFiles(1)
            autocmd VimEnter,BufNew * call s:UseConfigFiles(1)
        endif
    augroup END
endfunction

" }}}2

" Commands {{{2
command! ToolConfigEnable call s:ToolConfigEnable(1)
command! ToolConfigDisable call s:ToolConfigEnable(0)

command! ToolConfigReload call s:UseConfigFiles(0) " Reload ToolConfig files
" }}}2

" On startup, enable the autocommands
call s:ToolConfigEnable(1)

" }}}1

" UseConfigFiles function for different modes {{{1

function! s:UseConfigFiles_ExternalCommand(bufnr, target)
" Use external ToolConfig core (e.g., the C core)

    call toolconfig#util#disable_shell_slash(a:bufnr)
    let l:exec_path = shellescape(s:toolconfig_exec_path)
    call toolconfig#util#reset_shell_slash(a:bufnr)

    call toolconfig#core#spawn(a:bufnr, l:exec_path, a:target)
endfunction

" }}}1

let &cpo = s:saved_cpo
unlet! s:saved_cpo

" vim: fdm=marker fdc=3
