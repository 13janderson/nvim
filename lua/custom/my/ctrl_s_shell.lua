vim.cmd [[
" :shell / :opencode
"
" Creates per-pwd toggleable terminals with maximum 'scrollback'.
" For each terminal type, only ONE buffer of that type is visible at a time -
" opening a terminal for a pwd closes/hides any other visible terminal windows
" of the same type.
"
" Storage for per-pwd terminals:
"   g:term_shell_by_pwd[pwd]    = { bufnr, prevwid, prevtab, prevbuf }
"   g:term_opencode_by_pwd[pwd] = { bufnr, prevwid, prevtab, prevbuf }

" Close all other visible terminal windows except the current one
func! s:close_other_terminals(current_buf) abort
  " Ensure g:term_shell_by_pwd is a proper Vim dictionary (not Lua table)
  if !exists('g:term_shell_by_pwd') || type(g:term_shell_by_pwd) != type({})
    let g:term_shell_by_pwd = {}
  endif

  " Find all terminal buffers we're tracking
  let tracked_bufs = []
  for info in values(g:term_shell_by_pwd)
    if info.bufnr > 0 && bufexists(info.bufnr)
      call add(tracked_bufs, info.bufnr)
    endif
  endfor

  " Find all windows showing tracked terminal buffers (except current)
  for buf in tracked_bufs
    if buf == a:current_buf
      continue
    endif

    " Find all windows showing this buffer
    let wins = win_findbuf(buf)
    for winid in wins
      " Go to that window and close it
      let prev_win = win_getid()
      if win_gotoid(winid)
        " If it's the only window in the tab, close the tab
        if winnr('$') == 1 && tabpagenr('$') > 1
          close
        else
          " Hide the buffer and close the window
          hide
        endif
        " Try to go back to previous window
        call win_gotoid(prev_win)
      endif
    endfor
  endfor
endfunc

func! s:ctrl_s(cnt, here) abort
  let pwd = getcwd()
  " Ensure g:term_shell_by_pwd is a proper Vim dictionary (not Lua table)
  if !exists('g:term_shell_by_pwd') || type(g:term_shell_by_pwd) != type({})
    let g:term_shell_by_pwd = {}
  endif

  " If we're already in a terminal buffer, just go back to the previous window
  if &buftype ==# 'terminal'
    let tab = tabpagenr()
    let term_prevwid = win_getid()
    let curbuf = bufnr('%')

    " Try to find the terminal info for this buffer
    let term_info = {}
    let pwd_list = get(g:, 'term_shell_by_pwd', {})
    for [p, info] in items(pwd_list)
      if type(info) == type({}) && get(info, 'bufnr', 0) == curbuf
        let term_info = info
        break
      endif
    endfor

    if !empty(term_info)
      " Try to go back to the previous tab first
      let target_tab = get(term_info, 'prevtab', 0)
      let target_buf = get(term_info, 'prevbuf', 0)

      if target_tab > 0 && target_tab <= tabpagenr('$')
        " Find where to go on the target tab BEFORE switching
        let target_winnr = 0
        if target_buf > 0 && bufexists(target_buf)
          " Check if buffer is in a window on the target tab
          let winid = bufwinid(target_buf)
          if winid > 0
            let wininfo = win_id2tabwin(winid)
            " win_id2tabwin returns [tabnr, winnr] list
            if len(wininfo) >= 2 && wininfo[0] == target_tab
              let target_winnr = wininfo[1]
            endif
          endif
        endif

        " If buffer not found in a window, try the stored window ID
        if target_winnr == 0
          let prevwid = get(term_info, 'prevwid', 0)
          if prevwid > 0
            let prev_tabwin = win_id2tabwin(prevwid)
            if len(prev_tabwin) >= 2 && prev_tabwin[0] == target_tab && prev_tabwin[1] > 0
              let target_winnr = prev_tabwin[1]
            endif
          endif
        endif

        " Switch to the original tab
        exe 'tabnext ' . target_tab

        " Go to the target window if we found one
        if target_winnr > 0
          exe target_winnr . 'wincmd w'
        elseif target_buf > 0 && bufexists(target_buf)
          " Buffer exists but not in a window, show it in current window
          exe 'buffer ' . target_buf
        else
          " Last resort: wincmd p
          wincmd p
        endif
      else
        " Previous tab doesn't exist, fallback to window ID
        if get(term_info, 'prevwid', 0) > 0 && win_gotoid(term_info.prevwid)
          " Successfully switched to window
        else
          wincmd p
        endif
      endif
    else
      " Fallback: try wincmd p
      wincmd p
    endif

    return
  endif

  " Get or create terminal info for current pwd
  if !has_key(g:term_shell_by_pwd, pwd)
    let g:term_shell_by_pwd[pwd] = { 'bufnr': -1, 'prevwid': win_getid(), 'prevtab': tabpagenr(), 'prevbuf': bufnr('%') }
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
    " First close any other visible terminals
    call s:close_other_terminals(b)
    exe 'buffer' b
    setlocal nobuflisted
    let term_info.prevwid = win_getid()
    let term_info.prevtab = tabpagenr()
    let term_info.prevbuf = bufnr('#')
    return
  endif

  "
  " Return to previous window, maybe close the :shell tabpage.
  "
  if bufnr('%') == b
    let tab = tabpagenr()
    let term_prevwid = win_getid()

    " Try to go back to the previous tab first
    let target_tab = get(term_info, 'prevtab', 0)
    let target_buf = get(term_info, 'prevbuf', 0)

    if target_tab > 0 && target_tab <= tabpagenr('$')
      " Find where to go on the target tab BEFORE switching
      let target_winnr = 0
      if target_buf > 0 && bufexists(target_buf)
        " Check if buffer is in a window on the target tab
        let winid = bufwinid(target_buf)
        if winid > 0
          let wininfo = win_id2tabwin(winid)
          " win_id2tabwin returns [tabnr, winnr] list
          if len(wininfo) >= 2 && wininfo[0] == target_tab
            let target_winnr = wininfo[1]
          endif
        endif
      endif

      " If buffer not found in a window, try the stored window ID
      if target_winnr == 0
        let prevwid = get(term_info, 'prevwid', 0)
        if prevwid > 0
          let prev_tabwin = win_id2tabwin(prevwid)
          if len(prev_tabwin) >= 2 && prev_tabwin[0] == target_tab && prev_tabwin[1] > 0
            let target_winnr = prev_tabwin[1]
          endif
        endif
      endif

      " Switch to the original tab
      exe 'tabnext ' . target_tab

      " Go to the target window if we found one
      if target_winnr > 0
        exe target_winnr . 'wincmd w'
      elseif target_buf > 0 && bufexists(target_buf)
        " Buffer exists but not in a window, show it in current window
        exe 'buffer ' . target_buf
      else
        " Last resort: wincmd p
        wincmd p
      endif
    else
      " Previous tab doesn't exist, fallback to window ID
      if get(term_info, 'prevwid', 0) > 0 && win_gotoid(term_info.prevwid)
        " Successfully switched to window
      else
        wincmd p
      endif
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
  " Capture current context before potentially switching to terminal
  "
  let curbuf = bufnr('%')
  let curtab = tabpagenr()
  let curwinid = win_getid()

  "
  " Go to existing :shell or create a new one.
  ""

  " First, close any other visible terminals before showing this one
  call s:close_other_terminals(b)

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
        " Found in another tabpage - switch to that tab and window.
        let target_winid = ws[0]
        let target_tab = win_id2tabwin(target_winid)[0]
        if target_tab > 0
          exe 'tabnext ' . target_tab
        endif
        call win_gotoid(target_winid)
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

    " Check if a buffer with this name already exists (from previous session)
    let existing_buf = bufnr(fnameescape(bufname))
    if existing_buf > 0 && bufexists(existing_buf)
      " Reuse the existing buffer instead of creating a new one
      let term_info.bufnr = existing_buf
      let origbuf = bufnr('%')
      if !a:here
        exe ((a:cnt == 0) ? 'split' : a:cnt.'split')
      endif
      exe 'buffer ' . existing_buf
      " Ensure keymap is set up
      tnoremap <buffer> <C-s> <C-\><C-n>:call <SID>ctrl_s(0, v:false)<CR>
    else
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
  endif

  let term_info.prevwid = curwinid
  let term_info.prevtab = curtab
  let term_info.prevbuf = curbuf
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
    let visible = bufwinnr(info.bufnr) > 0 ? ' (visible)' : ''
    echo '  [' . exists . '] ' . pwd . visible
  endfor
endfunc
command! Shells call s:list_shells()

" Same per-pwd toggleable terminal logic for an opencode window on <C-x>.
func! s:close_other_opencode_terminals(current_buf) abort
  if !exists('g:term_opencode_by_pwd') || type(g:term_opencode_by_pwd) != type({})
    let g:term_opencode_by_pwd = {}
  endif

  let tracked_bufs = []
  for info in values(g:term_opencode_by_pwd)
    if info.bufnr > 0 && bufexists(info.bufnr)
      call add(tracked_bufs, info.bufnr)
    endif
  endfor

  for buf in tracked_bufs
    if buf == a:current_buf
      continue
    endif

    let wins = win_findbuf(buf)
    for winid in wins
      let prev_win = win_getid()
      if win_gotoid(winid)
        if winnr('$') == 1 && tabpagenr('$') > 1
          close
        else
          hide
        endif
        call win_gotoid(prev_win)
      endif
    endfor
  endfor
endfunc

func! s:ctrl_x(cnt, here) abort
  let pwd = getcwd()
  if !exists('g:term_opencode_by_pwd') || type(g:term_opencode_by_pwd) != type({})
    let g:term_opencode_by_pwd = {}
  endif

  if &buftype ==# 'terminal'
    let tab = tabpagenr()
    let term_prevwid = win_getid()
    let curbuf = bufnr('%')

    let term_info = {}
    let pwd_list = get(g:, 'term_opencode_by_pwd', {})
    for [p, info] in items(pwd_list)
      if type(info) == type({}) && get(info, 'bufnr', 0) == curbuf
        let term_info = info
        break
      endif
    endfor

    if !empty(term_info)
      let target_tab = get(term_info, 'prevtab', 0)
      let target_buf = get(term_info, 'prevbuf', 0)

      if target_tab > 0 && target_tab <= tabpagenr('$')
        let target_winnr = 0
        if target_buf > 0 && bufexists(target_buf)
          let winid = bufwinid(target_buf)
          if winid > 0
            let wininfo = win_id2tabwin(winid)
            if len(wininfo) >= 2 && wininfo[0] == target_tab
              let target_winnr = wininfo[1]
            endif
          endif
        endif

        if target_winnr == 0
          let prevwid = get(term_info, 'prevwid', 0)
          if prevwid > 0
            let prev_tabwin = win_id2tabwin(prevwid)
            if len(prev_tabwin) >= 2 && prev_tabwin[0] == target_tab && prev_tabwin[1] > 0
              let target_winnr = prev_tabwin[1]
            endif
          endif
        endif

        exe 'tabnext ' . target_tab

        if target_winnr > 0
          exe target_winnr . 'wincmd w'
        elseif target_buf > 0 && bufexists(target_buf)
          exe 'buffer ' . target_buf
        else
          wincmd p
        endif
      else
        if get(term_info, 'prevwid', 0) > 0 && win_gotoid(term_info.prevwid)
        else
          wincmd p
        endif
      endif
    else
      wincmd p
    endif

    return
  endif

  if !has_key(g:term_opencode_by_pwd, pwd)
    let g:term_opencode_by_pwd[pwd] = { 'bufnr': -1, 'prevwid': win_getid(), 'prevtab': tabpagenr(), 'prevbuf': bufnr('%') }
  endif

  let term_info = g:term_opencode_by_pwd[pwd]
  let b = term_info.bufnr
  let bufname = ':opencode:' . pwd

  if b > 0 && !bufexists(b)
    let b = -1
    let term_info.bufnr = -1
  endif

  if bufexists(b) && a:here
    call s:close_other_opencode_terminals(b)
    exe 'buffer' b
    setlocal nobuflisted
    let term_info.prevwid = win_getid()
    let term_info.prevtab = tabpagenr()
    let term_info.prevbuf = bufnr('#')
    return
  endif

  if bufnr('%') == b
    let tab = tabpagenr()
    let term_prevwid = win_getid()

    let target_tab = get(term_info, 'prevtab', 0)
    let target_buf = get(term_info, 'prevbuf', 0)

    if target_tab > 0 && target_tab <= tabpagenr('$')
      let target_winnr = 0
      if target_buf > 0 && bufexists(target_buf)
        let winid = bufwinid(target_buf)
        if winid > 0
          let wininfo = win_id2tabwin(winid)
          if len(wininfo) >= 2 && wininfo[0] == target_tab
            let target_winnr = wininfo[1]
          endif
        endif
      endif

      if target_winnr == 0
        let prevwid = get(term_info, 'prevwid', 0)
        if prevwid > 0
          let prev_tabwin = win_id2tabwin(prevwid)
          if len(prev_tabwin) >= 2 && prev_tabwin[0] == target_tab && prev_tabwin[1] > 0
            let target_winnr = prev_tabwin[1]
          endif
        endif
      endif

      exe 'tabnext ' . target_tab

      if target_winnr > 0
        exe target_winnr . 'wincmd w'
      elseif target_buf > 0 && bufexists(target_buf)
        exe 'buffer ' . target_buf
      else
        wincmd p
      endif
    else
      if get(term_info, 'prevwid', 0) > 0 && win_gotoid(term_info.prevwid)
      else
        wincmd p
      endif
    endif

    if bufnr('%') == b
      let bufs = filter(tabpagebuflist(), 'v:val != '.b)
      if len(bufs) > 0
        exe bufwinnr(bufs[0]).'wincmd w'
      else
        if &buftype !=# 'terminal' && getline(1) == '' && line('$') == 1
          bwipeout! %
          call s:ctrl_x(a:cnt, a:here)
        end
        return
      endif
    endif
    let term_info.prevwid = term_prevwid

    return
  endif

  let curbuf = bufnr('%')
  let curtab = tabpagenr()
  let curwinid = win_getid()

  call s:close_other_opencode_terminals(b)

  if a:cnt == 0 && bufexists(b) && winbufnr(term_info.prevwid) == b
    call win_gotoid(term_info.prevwid)
  elseif bufexists(b)
    let w = bufwinid(b)
    if a:cnt == 0 && w > 0
      call win_gotoid(w)
    else
      let ws = win_findbuf(b)
      if a:cnt == 0 && !empty(ws)
        let target_winid = ws[0]
        let target_tab = win_id2tabwin(target_winid)[0]
        if target_tab > 0
          exe 'tabnext ' . target_tab
        endif
        call win_gotoid(target_winid)
      else
        exe ((a:cnt == 0) ? 'split' : a:cnt.'split')
        exe 'buffer' b
      endif
    endif

    if &buftype !=# 'terminal' && getline(1) == '' && line('$') == 1
      call win_gotoid(term_info.prevwid)
      exe 'bwipeout!' b
      let term_info.bufnr = -1
      call s:ctrl_x(a:cnt, a:here)
    end
  else
    let existing_buf = bufnr(fnameescape(bufname))
    if existing_buf > 0 && bufexists(existing_buf)
      let term_info.bufnr = existing_buf
      let origbuf = bufnr('%')
      if !a:here
        exe ((a:cnt == 0) ? 'split' : a:cnt.'split')
      endif
      exe 'buffer ' . existing_buf
      tnoremap <buffer> <C-x> <C-\><C-n>:call <SID>ctrl_x(0, v:false)<CR>
    else
      let origbuf = bufnr('%')
      if !a:here
        exe ((a:cnt == 0) ? 'split' : a:cnt.'split')
      endif
      terminal opencode
      setlocal scrollback=-1
      exe 'file ' . fnameescape(bufname)
      let term_info.bufnr = bufnr('%')
      bwipeout! #
      exe 'autocmd VimLeavePre * bwipeout! ' . fnameescape(bufname)
      let @# = origbuf
      tnoremap <buffer> <C-x> <C-\><C-n>:call <SID>ctrl_x(0, v:false)<CR>
    endif
  endif

  let term_info.prevwid = curwinid
  let term_info.prevtab = curtab
  let term_info.prevbuf = curbuf
  setlocal nobuflisted
endfunc
nnoremap <C-x> :<C-u>call <SID>ctrl_x(v:count, v:false)<CR>
nnoremap '<C-x> :<C-u>call <SID>ctrl_x(v:count, v:true)<CR>

func! s:list_opencodes() abort
  let opencodes = get(g:, 'term_opencode_by_pwd', {})
  if empty(opencodes)
    echo "No active opencode terminals"
    return
  endif
  echo "Active opencode terminals by directory:"
  for [pwd, info] in items(opencodes)
    let exists = bufexists(info.bufnr) ? 'active' : 'stale'
    let visible = bufwinnr(info.bufnr) > 0 ? ' (visible)' : ''
    echo '  [' . exists . '] ' . pwd . visible
  endfor
endfunc
command! Opencodes call s:list_opencodes()
]]
