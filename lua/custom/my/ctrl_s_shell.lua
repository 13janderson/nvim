local M = {}

-- Per-pwd terminal state. Each entry: { bufnr, prevwid, prevtab, prevbuf }
local term_shell_by_pwd = {}
local term_opencode_by_pwd = {}
local term_hunk_by_pwd = {}

-- Registry of togglable terminal dicts. Add future terminal types here.
local term_dicts = {
  term_shell_by_pwd,
  term_opencode_by_pwd,
  term_hunk_by_pwd,
}

-- Keymaps applied to terminal buffers on creation, keyed by terminal type dict.
local keymap_configs = {
  [term_opencode_by_pwd] = {
    n = {
      { '<C-k>', 'i<PageUp><C-\\><C-n>',     { desc = 'Scroll up' } },
      { '<C-j>', 'i<PageDown><C-\\><C-n>',   { desc = 'Scroll down' } },
      { '<C-u>', 'i<C-PageUp><C-\\><C-n>',   { desc = 'Half page up' } },
      { '<C-d>', 'i<C-PageDown><C-\\><C-n>', { desc = 'Half page down' } },
      { 'gg',    'i<Home><C-\\><C-n>',       { desc = 'Jump to first message' } },
      { 'G',     'i<End><C-\\><C-n>',        { desc = 'Jump to last message' } },
    },
  },
  [term_hunk_by_pwd] = {
    t = {
      { '<C-C>', '<Esc>', { desc = 'Exit terminal mode' } },
    },
  },
}

-- Anchor window per pwd: the text window any terminal was first spawned from.
-- All toggles return here regardless of which terminal is active.
local anchor_by_pwd = {}

local function anchor_valid(pwd)
  local a = anchor_by_pwd[pwd]
  return a and a.winid and a.winid > 0 and vim.api.nvim_win_is_valid(a.winid)
end

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
        if vim.fn.winnr '$' == 1 and vim.fn.tabpagenr '$' > 1 then
          vim.cmd 'close'
        else
          vim.cmd 'hide'
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

  if target_tab and target_tab > 0 and target_tab <= vim.fn.tabpagenr '$' then
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
      vim.cmd 'wincmd p'
    end
  else
    local prevwid = term_info.prevwid
    if prevwid and prevwid > 0 then
      local ok = pcall(vim.api.nvim_set_current_win, prevwid)
      if not ok then
        vim.cmd 'wincmd p'
      end
    else
      vim.cmd 'wincmd p'
    end
  end
end

local function kill_hunk_sessions()
  local output = vim.fn.system('hunk session list --json')
  if vim.v.shell_error ~= 0 then
    return
  end
  local ok, data = pcall(vim.json.decode, output)
  if not ok or not data then
    return
  end
  local sessions = data.sessions
  if type(sessions) ~= 'table' then
    return
  end
  local cwd = vim.uv.cwd()
  for _, session in ipairs(sessions) do
    if session.pid and type(session.pid) == 'number' and session.cwd == cwd then
      vim.uv.kill(session.pid, 9)
    end
  end
end

local function ctrl_toggle(cnt, here, dict, cmd, terminal_close_key, other_visible, force_vsplit)
  local pwd = vim.fn.getcwd()

  -- Already in a terminal buffer owned by this toggle: return to previous context.
  -- A foreign (other-toggle) terminal falls through to open the requested one.
  if vim.bo.buftype == 'terminal' then
    local curbuf = vim.api.nvim_get_current_buf()
    for _, info in pairs(dict) do
      if info.bufnr == curbuf then
        goto_previous_context(info)
        return
      end
    end
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

  -- Bring the terminal buffer into a split in the current tab.
  if b > 0 and here then
    local prev_win = vim.api.nvim_get_current_win()
    local prev_tab = vim.api.nvim_get_current_tabpage()
    local prev_buf = vim.api.nvim_get_current_buf()
    local was_terminal = vim.bo.buftype == 'terminal'

    close_other_terminals(b, dict)

    -- Close the terminal buffer from any other windows/tabs.
    for _, winid in ipairs(vim.fn.win_findbuf(b)) do
      local ok = pcall(vim.api.nvim_set_current_win, winid)
      if ok then
        if vim.fn.winnr '$' == 1 and vim.fn.tabpagenr '$' > 1 then
          vim.cmd 'close'
        else
          vim.cmd 'hide'
        end
      end
    end
    pcall(vim.api.nvim_set_current_win, prev_win)

    if not was_terminal and not anchor_valid(pwd) then
      anchor_by_pwd[pwd] = { winid = prev_win, tabpage = prev_tab, bufnr = prev_buf }
    end

    vim.cmd(force_vsplit and 'rightbelow vsplit' or split_cmd(cnt, other_visible))
    vim.api.nvim_set_current_buf(b)
    vim.bo.buflisted = false

    if anchor_valid(pwd) then
      local a = anchor_by_pwd[pwd]
      term_info.prevwid = a.winid
      term_info.prevtab = a.tabpage
      term_info.prevbuf = a.bufnr
    else
      term_info.prevwid = prev_win
      term_info.prevtab = prev_tab
      term_info.prevbuf = prev_buf
    end
    return
  end

  -- Capture current context before switching to the terminal.
  local curbuf = vim.api.nvim_get_current_buf()
  local curtab = vim.api.nvim_get_current_tabpage()
  local curwinid = vim.api.nvim_get_current_win()

  if vim.bo.buftype == 'terminal' then
    -- Foreign terminal: return to the anchor window, not this terminal.
    if anchor_valid(pwd) then
      local a = anchor_by_pwd[pwd]
      curwinid = a.winid
      curtab = a.tabpage
      curbuf = a.bufnr
    end
  else
    -- Text window: record it as the anchor for this pwd if not yet set.
    if not anchor_valid(pwd) then
      anchor_by_pwd[pwd] = { winid = curwinid, tabpage = curtab, bufnr = curbuf }
    end
  end

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
        vim.cmd(force_vsplit and 'rightbelow vsplit' or split_cmd(cnt, other_visible))
        vim.api.nvim_set_current_buf(b)
      end
    end

    if vim.bo.buftype ~= 'terminal' and is_empty_buffer(0) then
      pcall(vim.api.nvim_set_current_win, term_info.prevwid)
      vim.api.nvim_buf_delete(b, { force = true })
      term_info.bufnr = -1
      ctrl_toggle(cnt, here, dict, cmd, terminal_close_key, other_visible, force_vsplit)
      return
    end
  else
    -- Create a new terminal for this pwd.
    if not here then
      vim.cmd(force_vsplit and 'rightbelow vsplit' or split_cmd(cnt, other_visible))
    end

    if cmd and cmd ~= '' then
      vim.cmd('terminal ' .. cmd)
    else
      vim.cmd 'terminal'
    end

    local new_buf = vim.api.nvim_get_current_buf()
    vim.bo.scrollback = -1
    term_info.bufnr = new_buf

    if terminal_close_key then
      vim.keymap.set('t', terminal_close_key, function()
        vim.cmd 'stopinsert'
        ctrl_toggle(0, false, dict, cmd, terminal_close_key, other_visible)
      end, { buffer = new_buf })
    end

    local buf_keymaps = keymap_configs[dict]
    if buf_keymaps then
      for mode, mappings in pairs(buf_keymaps) do
        for _, m in ipairs(mappings) do
          local opts = vim.deepcopy(m[3] or {})
          opts.buffer = new_buf
          vim.keymap.set(mode, m[1], m[2], opts)
        end
      end
    end
  end

  term_info.prevwid = curwinid
  term_info.prevtab = curtab
  term_info.prevbuf = curbuf
  vim.bo.buflisted = false
end

function M.ctrl_s(cnt, here)
  ctrl_toggle(cnt, here, term_shell_by_pwd, '', '<C-s>', terminal_visible_in_current_tab(term_opencode_by_pwd), false)
end

function M.ctrl_x(cnt, here)
  ctrl_toggle(cnt, here, term_opencode_by_pwd, "$SHELL -c 'opencode -c || opencode'", nil,
    terminal_visible_in_current_tab(term_shell_by_pwd), false)
end

function M.ctrl_g(cnt, here)
  local pwd = vim.fn.getcwd()
  local existing = term_hunk_by_pwd[pwd]
  if not (existing and buf_valid(existing.bufnr)) then
    kill_hunk_sessions()
  end
  ctrl_toggle(cnt, here, term_hunk_by_pwd, 'hunk diff --watch', '<C-g>',
    terminal_visible_in_current_tab(term_shell_by_pwd), true)
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

vim.keymap.set('n', '<C-g>', function()
  M.ctrl_g(vim.v.count, false)
end, { remap = false })

vim.keymap.set('n', "'<C-g>", function()
  M.ctrl_g(vim.v.count, true)
end, { remap = false })

-- Send selected lines to the opencode terminal for the current worktree.
-- ctrl+x shell tracks the opencode terminal per-pwd, so we know which buffer is
-- the relevant one for the current worktree.
vim.keymap.set('v', 'O', function()
  local start_line = vim.fn.line "'<"
  local end_line = vim.fn.line "'>"
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  if #lines == 0 then
    print 'No lines selected'
    return
  end

  local filename = vim.fn.expand '%:p'
  if filename == '' then
    filename = '[unnamed]'
  end

  local context = string.format('File: %s (lines %d-%d)\n', filename, start_line, end_line)
  local text = context .. table.concat(lines, '\n') .. '\n'

  local pwd = vim.fn.getcwd()
  local info = term_opencode_by_pwd[pwd]
  local chan = nil
  if info and buf_valid(info.bufnr) then
    chan = vim.bo[info.bufnr].channel
    if not chan or chan <= 0 then
      chan = nil
    end
  end

  if not chan then
    print 'No OpenCode terminal found for this worktree'
    return
  end

  vim.fn.chansend(chan, text)
  print(('Sent %d lines from %s (%d-%d) to OpenCode'):format(#lines, filename, start_line, end_line))
end, { desc = 'Send selected lines to OpenCode' })

-- Commands
-- vim.api.nvim_create_user_command('Shells', function()
--   list_terminals(term_shell_by_pwd, 'shell')
-- end, {})

-- vim.api.nvim_create_user_command('Opencodes', function()
--   list_terminals(term_opencode_by_pwd, 'opencode')
-- end, {})

-- Re-set keymaps after plugins (e.g. vim-ug) load and may have overwritten them.
vim.api.nvim_create_autocmd('UIEnter', {
  once = true,
  callback = function()
    vim.keymap.set('n', '<C-g>', function()
      M.ctrl_g(vim.v.count, false)
    end, { remap = false })
    vim.keymap.set('n', "'<C-g>", function()
      M.ctrl_g(vim.v.count, true)
    end, { remap = false })
  end,
})

-- Wipe tracked terminal buffers on exit so they don't leak into sessions.
vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = function()
    for _, dict in ipairs(term_dicts) do
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
