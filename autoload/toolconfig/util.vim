" autoload/toolconfig/util.vim: ToolConfig Vimscript utils
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

" shellslash handling {{{1
function! toolconfig#util#disable_shell_slash(bufnr)
    " disable shellslash for proper escaping of Windows paths

    " In Windows, 'shellslash' also changes the behavior of 'shellescape'.
    " It makes 'shellescape' behave like in UNIX environment. So ':setl
    " noshellslash' before evaluating 'shellescape' and restore the
    " settings afterwards when 'shell' does not contain 'sh' somewhere.
    let l:shell = getbufvar(a:bufnr, '&shell')
    if has('win32') && empty(matchstr(l:shell, 'sh'))
        let s:old_shellslash = getbufvar(a:bufnr, '&shellslash')
        setbufvar(a:bufnr, '&shellslash', 0)
    endif
endfunction

function! toolconfig#util#reset_shell_slash(bufnr)
    " reset shellslash to the user-set value, if any
    if exists('s:old_shellslash')
        setbufvar(a:bufnr, '&shellslash', s:old_shellslash)
        unlet! s:old_shellslash
    endif
endfunction
" }}}1
