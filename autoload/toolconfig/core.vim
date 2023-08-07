" autoload/toolconfig/core.vim: Interact with the ToolConfig core
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

" TODO RESUME HERE --- invoke the python module

function! toolconfig#core#spawn(bufnr, cmd, target)
" Spawn external ToolConfig. Used by UseConfigFiles_ExternalCommand()

    let l:cmd = a:cmd

    if empty(l:cmd)
        throw 'No cmd provided'
    endif

    let l:config = {}

    call toolconfig#util#disable_shell_slash(a:bufnr)
    let l:cmd = l:cmd . ' ' . shellescape(a:target)
    call toolconfig#util#reset_shell_slash(a:bufnr)

    let l:parsing_result = split(system(l:cmd), '\v[\r\n]+')

    " if ToolConfig core's exit code is not zero, give out an error
    " message
    if v:shell_error != 0
        echohl ErrorMsg
        echo 'Failed to execute "' . l:cmd . '". Exit code: ' .
                    \ v:shell_error
        echo ''
        echo 'Message:'
        echo l:parsing_result
        echohl None
        return
    endif

    if g:ToolConfig_verbose
        echo 'Output from ToolConfig core executable:'
        echo l:parsing_result
    endif

    for one_line in l:parsing_result
        let l:eq_pos = stridx(one_line, '=')

        if l:eq_pos == -1 " = is not found. Skip this line
            continue
        endif

        let l:eq_left = strpart(one_line, 0, l:eq_pos)
        if l:eq_pos + 1 < strlen(one_line)
            let l:eq_right = strpart(one_line, l:eq_pos + 1)
        else
            let l:eq_right = ''
        endif

        let l:config[l:eq_left] = l:eq_right
    endfor

    call s:ApplyConfig(a:bufnr, l:config)
endfunction
