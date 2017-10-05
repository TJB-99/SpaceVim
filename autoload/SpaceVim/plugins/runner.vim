"=============================================================================
" runner.vim --- code runner for SpaceVim
" Copyright (c) 2016-2017 Shidong Wang & Contributors
" Author: Shidong Wang < wsdjeg at 163.com >
" URL: https://spacevim.org
" License: MIT license
"=============================================================================

let s:JOB = SpaceVim#api#import('job')
let s:BUFFER = SpaceVim#api#import('vim#buffer')

let s:runners = {}

let s:bufnr = 0

function! s:open_win() abort
  botright split __runner__
  let lines = &lines * 30 / 100
  exe 'resize ' . lines
  setlocal buftype=nofile bufhidden=wipe nobuflisted nolist noswapfile nowrap cursorline nospell nonu norelativenumber
  set filetype=SpaceVimRunner
  let s:bufnr = bufnr('%')
endfunction


function! s:async_run(runner) abort
  let cmd = printf(a:runner, bufname('#'))
  call s:JOB.start(cmd,{
        \ 'on_stdout' : function('s:on_stdout'),
        \ 'on_stderr' : function('s:on_stderr'),
        \ 'on_exit' : function('s:on_exit'),
        \ })
endfunction


function! s:update_statusline() abort
  redrawstatus
endfunction

function! SpaceVim#plugins#runner#reg_runner(ft, runner)
  let s:runners[a:ft] = a:runner
endfunction

function! SpaceVim#plugins#runner#open()
  let s:lines = 0
  let s:status = {
        \ 'is_running' : 0,
        \ 'is_exit' : 0,
        \ 'has_errors' : 0,
        \ 'exit_code' : 0
        \ }
  let runner = get(s:runners, &filetype, '')
  if !empty(runner)
    call s:open_win()
    call s:async_run(runner)
    call s:update_statusline()
  endif
endfunction

function! s:on_stdout(job_id, data, event) abort
  call s:BUFFER.buf_set_lines(s:bufnr, s:lines , s:lines + 1, 0, a:data)
  let s:lines += len(a:data)
  call s:update_statusline()
endfunction

function! s:on_stderr(job_id, data, event) abort
  let s:status.has_errors = 1
  call s:update_statusline()
endfunction

function! s:on_exit(job_id, data, event) abort
  let s:status.is_exit = 1
  let s:status.exit_code = a:data
  call s:update_statusline()

endfunction


function! SpaceVim#plugins#runner#status()
  if s:status.is_running == 1
  elseif s:status.is_exit == 1
    return 'exit code : ' . s:status.exit_code
  endif
endfunction
