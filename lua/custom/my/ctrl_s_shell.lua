local M = {}

-- Per-pwd terminal state. Each entry: { bufnr, prevwid, prevtab, prevbuf }
local term_shell_by_pwd = {}
local term_opencode_by_pwd = {}

local function buf_valid(b)
  return b and b > 0 and vim.api.nvim_buf_is_valid(b)
end

local function is_empty_buffer(buf)
  local lines = vim.api.nvim_buf_get_lines(buf or 0, 0, -1, false)
  return #lines == 1 and lines[1] == ''
end

local function close_other_terminals(current_buf, dict)
  for _, info in pairs(dict) do
    local b = info.bufnr
    if not buf_valid(b) or b == current_buf then
      goto next_buf
    end

    local wins = vim.fn.win_findbuf(b)
    for _, winid in ipairs(wins) do
      local prev_win = vim.api.nvim_get_current_win()
      local ok = pcall(vim.api.nvim_set_current_win, winid)
      if ok then
        if vim.fn.winnr('$') == 1 and vim.fn.tabpagenr('$') > 1 then
          vim.cmd('close')
        else
          vim.cmd('hide')
        end
        pcall(vim.api.nvim_set_current_win, prev_win)
      end
    end

    ::next_buf::
  end
end

local function terminal_visible_in_current_tab(dict)
  local current_tab = vim.fn.tabpagenr()
  for _, info in pairs(dict) do
    local b = info.bufnr
    if buf_valid(b) then
      for _, winid in ipairs(vim.fn.win_findbuf(b)) do
        local wininfo = vim.fn.win_id2tabwin(winid)
        if #wininfo >= 2 and wininfo[1] == current_tab then
          return true
        end
      end
    end
  end
  return false
end

local function split_cmd(cnt, other_visible)
  if cnt == 0 and other_visible then
    return 'vsplit'
  elseif cnt == 0 then
    return 'split'
  else
    return cnt .. 'split'
  end
end

local function goto_previous_context(term_info)
  local target_tab = term_info.prevtab
  local target_buf = term_info.prevbuf
  local target_winnr = 0

  if target_tab and target_tab > 0 and target_tab <= vim.fn.tabpagenr('$') then
    if buf_valid(target_buf) then
      local winid = vim.fn.bufwinid(target_buf)
      if winid > 0 then
        local wininfo = vim.fn.win_id2tabwin(winid)
        if #wininfo >= 2 and wininfo[1] == target_tab then
          target_winnr = wininfo[2]
        end
      end
    end

    if target_winnr == 0 then
      local prevwid = term_info.prevwid
      if prevwid and prevwid > 0 then
        local prev_tabwin = vim.fn.win_id2tabwin(prevwid)
        if #prev_tabwin >= 2 and prev_tabwin[1] == target_tab and prev_tabwin[2] > 0 then
          target_winnr = prev_tabwin[2]
        end
      end
    end

    vim.cmd('tabnext ' .. target_tab)
    if target_winnr > 0 then
      vim.cmd(target_winnr .. 'wincmd w')
    elseif buf_valid(target_buf) then
      vim.api.nvim_set_current_buf(target_buf)
    else
      vim.cmd('wincmd p')
    end
  else
    local prevwid = term_info.prevwid
    if prevwid and prevwid > 0 then
      local ok = pcall(vim.api.nvim_set_current_win, prevwid)
      if not ok then
        vim.cmd('wincmd p')
      end
    else
      vim.cmd('wincmd p')
    end
  end
end

local function ctrl_toggle(cnt, here, dict, cmd, terminal_close_key, other_visible)
  local pwd = vim.fn.getcwd()

  -- Already in a terminal buffer: return to the previous context.
  if vim.bo.buftype == 'terminal' then
    local curbuf = vim.api.nvim_get_current_buf()
    local term_info = nil
    for _, info in pairs(dict) do
      if info.bufnr == curbuf then
        term_info = info
        break
      end
    end

    if term_info then
      goto_previous_context(term_info)
    else
      vim.cmd('wincmd p')
    end
    return
  end

  -- Get or create terminal info for current pwd.
  if not dict[pwd] then
    dict[pwd] = {
      bufnr = -1,
      prevwid = vim.api.nvim_get_current_win(),
      prevtab = vim.api.nvim_get_current_tabpage(),
      prevbuf = vim.api.nvim_get_current_buf(),
    }
  end

  local term_info = dict[pwd]
  local b = term_info.bufnr

  -- Validate buffer still exists.
  if not buf_valid(b) then
    b = -1
    term_info.bufnr = -1
  end

  -- Edit the terminal buffer in the current window.
  if b > 0 and here then
    close_other_terminals(b, dict)
    vim.api.nvim_set_current_buf(b)
    vim.bo.buflisted = false
    term_info.prevwid = vim.api.nvim_get_current_win()
    term_info.prevtab = vim.api.nvim_get_current_tabpage()
    term_info.prevbuf = vim.fn.bufnr('#')
    return
  end

  -- Current buffer is the terminal: hide it and return to previous context.
  if vim.api.nvim_get_current_buf() == b then
    local term_prevwid = vim.api.nvim_get_current_win()
    goto_previous_context(term_info)

    if vim.api.nvim_get_current_buf() == b then
      local bufs = vim.tbl_filter(function(buf)
        return buf ~= b
      end, vim.fn.tabpagebuflist())

      if #bufs > 0 then
        local winnr = vim.fn.bufwinnr(bufs[1])
        if winnr > 0 then
          vim.cmd(winnr .. 'wincmd w')
        end
      else
        if vim.bo.buftype ~= 'terminal' and is_empty_buffer(0) then
          vim.api.nvim_buf_delete(0, { force = true })
          ctrl_toggle(cnt, here, dict, cmd, terminal_close_key, other_visible)
        end
        return
      end
    end

    term_info.prevwid = term_prevwid
    return
  end

  -- Capture current context before switching to the terminal.
  local curbuf = vim.api.nvim_get_current_buf()
  local curtab = vim.api.nvim_get_current_tabpage()
  local curwinid = vim.api.nvim_get_current_win()

  close_other_terminals(b, dict)

  -- Go to existing terminal or create a new one.
  if cnt == 0 and b > 0 and vim.fn.winbufnr(term_info.prevwid) == b then
    vim.api.nvim_set_current_win(term_info.prevwid)
  elseif b > 0 then
    local w = vim.fn.bufwinid(b)
    if cnt == 0 and w > 0 then
      vim.api.nvim_set_current_win(w)
    else
      local ws = vim.fn.win_findbuf(b)
      if cnt == 0 and not vim.tbl_isempty(ws) then
        local target_winid = ws[1]
        local target_tab = vim.fn.win_id2tabwin(target_winid)[1]
        if target_tab and target_tab > 0 then
          vim.cmd('tabnext ' .. target_tab)
        end
        vim.api.nvim_set_current_win(target_winid)
      else
        vim.cmd(split_cmd(cnt, other_visible))
        vim.api.nvim_set_current_buf(b)
      end
    end

    if vim.bo.buftype ~= 'terminal' and is_empty_buffer(0) then
      pcall(vim.api.nvim_set_current_win, term_info.prevwid)
      vim.api.nvim_buf_delete(b, { force = true })
      term_info.bufnr = -1
      ctrl_toggle(cnt, here, dict, cmd, terminal_close_key, other_visible)
      return
    end
  else
    -- Create a new terminal for this pwd.
    if not here then
      vim.cmd(split_cmd(cnt, other_visible))
    end

    if cmd and cmd ~= '' then
      vim.cmd('terminal ' .. cmd)
    else
      vim.cmd('terminal')
    end

    local new_buf = vim.api.nvim_get_current_buf()
    vim.bo.scrollback = -1
    term_info.bufnr = new_buf

    if terminal_close_key then
      vim.keymap.set('t', terminal_close_key, function()
        vim.cmd('stopinsert')
        ctrl_toggle(0, false, dict, cmd, terminal_close_key, other_visible)
      end, { buffer = new_buf })
    end
  end

  term_info.prevwid = curwinid
  term_info.prevtab = curtab
  term_info.prevbuf = curbuf
  vim.bo.buflisted = false
end

function M.ctrl_s(cnt, here)
  ctrl_toggle(cnt, here, term_shell_by_pwd, '', '<C-s>', terminal_visible_in_current_tab(term_opencode_by_pwd))
end

function M.ctrl_x(cnt, here)
  ctrl_toggle(cnt, here, term_opencode_by_pwd, "$SHELL -c 'opencode -c || opencode'", nil, terminal_visible_in_current_tab(term_shell_by_pwd))
end

local function list_terminals(dict, label)
  if vim.tbl_isempty(dict) then
    print('No active ' .. label .. ' terminals')
    return
  end

  print('Active ' .. label .. ' terminals by directory:')
  for pwd, info in pairs(dict) do
    local exists = vim.api.nvim_buf_is_valid(info.bufnr) and 'active' or 'stale'
    local visible = vim.fn.bufwinnr(info.bufnr) > 0 and ' (visible)' or ''
    print('  [' .. exists .. '] ' .. pwd .. visible)
  end
end

-- Keymaps
vim.keymap.set('n', '<C-s>', function()
  M.ctrl_s(vim.v.count, false)
end, { remap = false })

vim.keymap.set('n', "'<C-s>", function()
  M.ctrl_s(vim.v.count, true)
end, { remap = false })

vim.keymap.set('n', '<C-x>', function()
  M.ctrl_x(vim.v.count, false)
end, { remap = false })

vim.keymap.set('n', "'<C-x>", function()
  M.ctrl_x(vim.v.count, true)
end, { remap = false })

-- Commands
vim.api.nvim_create_user_command('Shells', function()
  list_terminals(term_shell_by_pwd, 'shell')
end, {})

vim.api.nvim_create_user_command('Opencodes', function()
  list_terminals(term_opencode_by_pwd, 'opencode')
end, {})

-- Wipe tracked terminal buffers on exit so they don't leak into sessions.
vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = function()
    for _, dict in ipairs({ term_shell_by_pwd, term_opencode_by_pwd }) do
      for _, info in pairs(dict) do
        local b = info.bufnr
        if buf_valid(b) then
          pcall(vim.api.nvim_buf_delete, b, { force = true })
        end
        info.bufnr = -1
      end
    end
  end,
})

return M
