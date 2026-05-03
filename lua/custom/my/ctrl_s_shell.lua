vim.cmd [[
" :shell
"
" Creates a per-pwd toggleable terminal with maximum 'scrollback'.
" Each working directory gets its own terminal buffer, useful for git worktrees.
"
" Storage for per-pwd terminals: g:term_shell_by_pwd[pwd] = { bufnr, prevwid }
func! s:ctrl_s(cnt, here) abort
  let pwd = getcwd()
  let g:term_shell_by_pwd = get(g:, 'term_shell_by_pwd', {})
  
  " If we're already in a terminal buffer, just go back to the previous window
  " instead of spawning a new terminal for a different cwd
  if &buftype ==# 'terminal'
    let tab = tabpagenr()
    let term_prevwid = win_getid()
    let curbuf = bufnr('%')
    
    " Try to find the terminal info for this buffer to get prevwid
    let term_info = {}
    for [p, info] in items(g:term_shell_by_pwd)
      if info.bufnr == curbuf
        let term_info = info
        break
      endif
    endfor
    
    if !empty(term_info) && win_gotoid(term_info.prevwid)
      " Successfully went back to previous window
    else
      " Fallback: try wincmd p
      wincmd p
    endif
    
    if tabpagewinnr(tab, '$') == 1 && tabpagenr() != tab
      " Close the terminal tabpage if it's the only window in the tabpage.
      exe 'tabclose' tab
    endif
    
    return
  endif
  
  " Get or create terminal info for current pwd
  if !has_key(g:term_shell_by_pwd, pwd)
    let g:term_shell_by_pwd[pwd] = { 'bufnr': -1, 'prevwid': win_getid() }
  endif
  
  let term_info = g:term_shell_by_pwd[pwd]
  let b = term_info.bufnr
  let bufname = ':shell:' . pwd

  " Validate buffer still exists (might have been deleted)
  if b > 0 && !bufexists(b)
    let b = -1
    let term_info.bufnr = -1
  endif

  if bufexists(b) && a:here  " Edit the :shell buffer in this window.
    exe 'buffer' b
    setlocal nobuflisted
    let term_info.prevwid = win_getid()
    return
  endif

  "
  " Return to previous window, maybe close the :shell tabpage.
  "
  if bufnr('%') == b
    let tab = tabpagenr()
    let term_prevwid = win_getid()
    if !win_gotoid(term_info.prevwid)
      wincmd p
    endif
    if tabpagewinnr(tab, '$') == 1 && tabpagenr() != tab
    " Close the :shell tabpage if it's the only window in the tabpage.
      exe 'tabclose' tab
    endif
    if bufnr('%') == b
      " Edge-case: :shell buffer showing in multiple windows in curtab.
      " Find a non-:shell window in curtab.
      let bufs = filter(tabpagebuflist(), 'v:val != '.b)
      if len(bufs) > 0
        exe bufwinnr(bufs[0]).'wincmd w'
      else
        " Last resort: can happen if :mksession restores an old :shell.
        " tabprevious
        if &buftype !=# 'terminal' && getline(1) == '' && line('$') == 1
          " XXX: cleanup stale, empty :shell buffer (caused by :mksession).
          bwipeout! %
          " Try again.
          call s:ctrl_s(a:cnt, a:here)
        end
        return
      endif
    endif
    let term_info.prevwid = term_prevwid

    return
  endif

  "
  " Go to existing :shell or create a new one.
  "
  let curwinid = win_getid()
  if a:cnt == 0 && bufexists(b) && winbufnr(term_info.prevwid) == b
    " Go to :shell displayed in the previous window.
    call win_gotoid(term_info.prevwid)
  elseif bufexists(b)
    " Go to existing :shell.

    let w = bufwinid(b)
    if a:cnt == 0 && w > 0
      " Found in current tabpage.
      call win_gotoid(w)
    else
      " Not in current tabpage.
      let ws = win_findbuf(b)
      if a:cnt == 0 && !empty(ws)
        " Found in another tabpage.
        call win_gotoid(ws[0])
      else
        " Not in any existing window; open a split (horizontal by default).
        exe ((a:cnt == 0) ? 'split' : a:cnt.'split')
        exe 'buffer' b
      endif
    endif

    if &buftype !=# 'terminal' && getline(1) == '' && line('$') == 1
      call win_gotoid(term_info.prevwid)
      " XXX: cleanup stale, empty :shell buffer (caused by :mksession).
      exe 'bwipeout!' b
      let term_info.bufnr = -1
      " Try again.
      call s:ctrl_s(a:cnt, a:here)
    end
  else
    " Create new :shell for this pwd.

    let origbuf = bufnr('%')
    if !a:here
      exe ((a:cnt == 0) ? 'split' : a:cnt.'split')
    endif
    terminal
    setlocal scrollback=-1
    " Name the buffer with pwd context
    exe 'file ' . fnameescape(bufname)
    " Store the buffer number for this pwd
    let term_info.bufnr = bufnr('%')
    " XXX: original term:// buffer hangs around after :file ...
    bwipeout! #
    " Set up cleanup on vim leave for this buffer
    exe 'autocmd VimLeavePre * bwipeout! ' . fnameescape(bufname)
    " Set alternate buffer to something intuitive.
    let @# = origbuf
    tnoremap <buffer> <C-s> <C-\><C-n>:call <SID>ctrl_s(0, v:false)<CR>
  endif

  let term_info.prevwid = curwinid
  setlocal nobuflisted
endfunc
nnoremap <C-s> :<C-u>call <SID>ctrl_s(v:count, v:false)<CR>
nnoremap '<C-s> :<C-u>call <SID>ctrl_s(v:count, v:true)<CR>

" Optional: Command to list all active pwd terminals
func! s:list_shells() abort
  let shells = get(g:, 'term_shell_by_pwd', {})
  if empty(shells)
    echo "No active shells"
    return
  endif
  echo "Active shells by directory:"
  for [pwd, info] in items(shells)
    let exists = bufexists(info.bufnr) ? 'active' : 'stale'
    echo '  [' . exists . '] ' . pwd
  endfor
endfunc
command! Shells call s:list_shells()
]]
