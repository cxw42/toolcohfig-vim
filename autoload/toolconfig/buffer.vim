" autoload/toolconfig/buffer.vim: ToolConfig buffer-handling code
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


" Set the buffer options {{{1
function! toolconfig#buffer#set_charset(bufnr, charset) abort " apply config['charset']

    " Remember the buffer's state so we can set `nomodifed` at the end
    " if appropriate.
    let l:orig_fenc = getbufvar(a:bufnr, "&fileencoding")
    let l:orig_enc = getbufvar(a:bufnr, "&encoding")
    let l:orig_modified = getbufvar(a:bufnr, "&modified")

    if a:charset == "utf-8"
        call setbufvar(a:bufnr, '&fileencoding', 'utf-8')
        call setbufvar(a:bufnr, '&bomb', 0)
    elseif a:charset == "utf-8-bom"
        call setbufvar(a:bufnr, '&fileencoding', 'utf-8')
        call setbufvar(a:bufnr, '&bomb', 1)
    elseif a:charset == "latin1"
        call setbufvar(a:bufnr, '&fileencoding', 'latin1')
        call setbufvar(a:bufnr, '&bomb', 0)
    elseif a:charset == "utf-16be"
        call setbufvar(a:bufnr, '&fileencoding', 'utf-16be')
        call setbufvar(a:bufnr, '&bomb', 1)
    elseif a:charset == "utf-16le"
        call setbufvar(a:bufnr, '&fileencoding', 'utf-16le')
        call setbufvar(a:bufnr, '&bomb', 1)
    endif

    let l:new_fenc = getbufvar(a:bufnr, "&fileencoding")

    " If all we did was change the fileencoding from the default to a copy
    " of the default, we didn't actually modify the file.
    if !l:orig_modified && (l:orig_fenc ==# '') && (l:new_fenc ==# l:orig_enc)
        if g:ToolConfig_verbose
            echo 'Setting nomodified on buffer ' . a:bufnr
        endif
        call setbufvar(a:bufnr, '&modified', 0)
    endif
endfunction

function! toolconfig#buffer#apply_config(bufnr, config) abort
    if g:ToolConfig_verbose
        echo 'Options: ' . string(a:config)
    endif

    if s:IsRuleActive('indent_style', a:config)
        if a:config["indent_style"] == "tab"
            call setbufvar(a:bufnr, '&expandtab', 0)
        elseif a:config["indent_style"] == "space"
            call setbufvar(a:bufnr, '&expandtab', 1)
        endif
    endif

    if s:IsRuleActive('tab_width', a:config)
        let l:tabstop = str2nr(a:config["tab_width"])
        call setbufvar(a:bufnr, '&tabstop', l:tabstop)
    else
        " Grab the current ts so we can use it below
        let l:tabstop = getbufvar(a:bufnr, '&tabstop')
    endif

    if s:IsRuleActive('indent_size', a:config)
        " if indent_size is 'tab', set shiftwidth to tabstop;
        " if indent_size is a positive integer, set shiftwidth to the integer
        " value
        if a:config["indent_size"] == "tab"
            call setbufvar(a:bufnr, '&shiftwidth', l:tabstop)
            if type(g:ToolConfig_softtabstop_tab) != type([])
                call setbufvar(a:bufnr, '&softtabstop',
                            \ g:ToolConfig_softtabstop_tab > 0 ?
                            \ l:tabstop : g:ToolConfig_softtabstop_tab)
            endif
        else
            let l:indent_size = str2nr(a:config["indent_size"])
            if l:indent_size > 0
                call setbufvar(a:bufnr, '&shiftwidth', l:indent_size)
                if type(g:ToolConfig_softtabstop_space) != type([])
                    call setbufvar(a:bufnr, '&softtabstop',
                            \ g:ToolConfig_softtabstop_space > 0 ?
                            \ l:indent_size : g:ToolConfig_softtabstop_space)
                endif
            endif
        endif

    endif

    if s:IsRuleActive('end_of_line', a:config) &&
                \ getbufvar(a:bufnr, '&modifiable')
        if a:config["end_of_line"] == "lf"
            call setbufvar(a:bufnr, '&fileformat', 'unix')
        elseif a:config["end_of_line"] == "crlf"
            call setbufvar(a:bufnr, '&fileformat', 'dos')
        elseif a:config["end_of_line"] == "cr"
            call setbufvar(a:bufnr, '&fileformat', 'mac')
        endif
    endif

    if s:IsRuleActive('charset', a:config) &&
                \ getbufvar(a:bufnr, '&modifiable')
        call toolconfig#buffer#set_charset(a:bufnr, a:config["charset"])
    endif

    augroup toolconfig_trim_trailing_whitespace
        autocmd! BufWritePre <buffer>
        if s:IsRuleActive('trim_trailing_whitespace', a:config) &&
                    \ get(a:config, 'trim_trailing_whitespace', 'false') ==# 'true'
            execute 'autocmd BufWritePre <buffer=' . a:bufnr . '> call s:TrimTrailingWhitespace()'
        endif
    augroup END

    if s:IsRuleActive('insert_final_newline', a:config)
        if exists('+fixendofline')
            if a:config["insert_final_newline"] == "false"
                call setbufvar(a:bufnr, '&fixendofline', 0)
            else
                call setbufvar(a:bufnr, '&fixendofline', 1)
            endif
        elseif  exists(':SetNoEOL') == 2
            if a:config["insert_final_newline"] == "false"
                silent! SetNoEOL    " Use the PreserveNoEOL plugin to accomplish it
            endif
        endif
    endif

    " highlight the columns following max_line_length
    if s:IsRuleActive('max_line_length', a:config) &&
                \ a:config['max_line_length'] != 'off'
        let l:max_line_length = str2nr(a:config['max_line_length'])

        if l:max_line_length >= 0
            call setbufvar(a:bufnr, '&textwidth', l:max_line_length)
            if g:ToolConfig_preserve_formatoptions == 0
                " setlocal formatoptions+=tc
                let l:fo = getbufvar(a:bufnr, '&formatoptions')
                if l:fo !~# 't'
                    let l:fo .= 't'
                endif
                if l:fo !~# 'c'
                    let l:fo .= 'c'
                endif
                call setbufvar(a:bufnr, '&formatoptions', l:fo)
            endif
        endif

        if exists('+colorcolumn')
            if l:max_line_length > 0
                if g:ToolConfig_max_line_indicator == 'line'
                    " setlocal colorcolumn+=+1
                    let l:cocol = getbufvar(a:bufnr, '&colorcolumn')
                    if !empty(l:cocol)
                        let l:cocol .= ','
                    endif
                    let l:cocol .= '+1'
                    call setbufvar(a:bufnr, '&colorcolumn', l:cocol)
                elseif g:ToolConfig_max_line_indicator == 'fill' &&
                            \ l:max_line_length < getbufvar(a:bufnr, '&columns')
                    " Fill only if the columns of screen is large enough
                    call setbufvar(a:bufnr, '&colorcolumn',
                            \ join(range(l:max_line_length+1,
                            \           getbufvar(a:bufnr, '&columns')),
                            \       ','))
                elseif g:ToolConfig_max_line_indicator == 'exceeding'
                    call setbufvar(a:bufnr, '&colorcolumn', '')
                    for l:match in getmatches()
                        if get(l:match, 'group', '') == 'ColorColumn'
                            call matchdelete(get(l:match, 'id'))
                        endif
                    endfor
                    call matchadd('ColorColumn',
                        \ '\%' . (l:max_line_length + 1) . 'v.', 100)
                elseif g:ToolConfig_max_line_indicator == 'fillexceeding'
                    let &l:colorcolumn = ''
                    for l:match in getmatches()
                        if get(l:match, 'group', '') == 'ColorColumn'
                            call matchdelete(get(l:match, 'id'))
                        endif
                    endfor
                    call matchadd('ColorColumn',
                        \ '\%'. (l:max_line_length + 1) . 'v.\+', -1)
                endif
            endif
        endif
    endif

    call toolconfig#ApplyHooks(a:config)
endfunction

" }}}1

function! s:TrimTrailingWhitespace() " {{{1
    " Called from within a buffer-specific autocmd, so we can use '%'
    if getbufvar('%', '&modifiable')
        " don't lose user position when trimming trailing whitespace
        let s:view = winsaveview()
        try
            silent! keeppatterns keepjumps %s/\s\+$//e
        finally
            call winrestview(s:view)
        endtry
    endif
endfunction " }}}1

function! s:IsRuleActive(name, config) " {{{1
    return index(g:ToolConfig_disable_rules, a:name) < 0 &&
                 \ has_key(a:config, a:name)
endfunction "}}}1
