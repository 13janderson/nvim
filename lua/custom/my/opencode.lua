local function get_terminal_channel(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Check if it's a terminal buffer
  if vim.bo[bufnr].buftype ~= 'terminal' then
    return nil
  end

  local channel = vim.bo[bufnr].channel
  if channel and channel > 0 then
    return channel
  end

  return nil
end

local function is_opencode_running(chan)
  if not chan then
    return false
  end

  local ok, pid = pcall(vim.fn.jobpid, chan)
  if not ok or not pid then
    return false
  end

  local ok2, children = pcall(vim.api.nvim_get_proc_children, pid)
  if not ok2 or not children or #children == 0 then
    return false
  end

  local child = children[1]
  local is_running = false
  local jobid = vim.fn.jobstart({ 'ps', '-q', tostring(child), '-o', 'comm=' }, {
    on_stdout = function(_, line)
      for _, l in ipairs(line) do
        local trim = vim.fn.trim(l)
        if trim == 'opencode' then
          is_running = true
        end
      end
    end,
  })
  vim.fn.jobwait { jobid }

  return is_running
end

-- Track the last entered terminal buffer
local last_terminal_bufnr = nil

vim.api.nvim_create_autocmd('BufEnter', {
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()

    -- Only process terminal buffers
    if vim.bo[bufnr].buftype ~= 'terminal' then
      return
    end

    -- Track this as the most recently used terminal
    last_terminal_bufnr = bufnr

    local chan = get_terminal_channel(bufnr)

    if not chan then
      print 'No terminal channel found'
      return
    end

    vim.defer_fn(function()
      if is_opencode_running(chan) then
        -- Terminal buffer keymaps for easier navigation
        vim.api.nvim_buf_set_keymap(bufnr, 't', '<Esc>', '<C-\\><C-n>',
          { noremap = true, silent = true, desc = 'Exit terminal mode' })
        -- Opencode scrolling normal mode scrolling in terminal (send to opencode)
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-k>', 'i<PageUp><C-\\><C-n>',
          { noremap = true, silent = true, desc = 'Scroll up' })
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-j>', 'i<PageDown><C-\\><C-n>',
          { noremap = true, silent = true, desc = 'Scroll down' })
        -- Matches tui.json: ctrl+b/f for half page scrolling
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-u>', 'i<C-PageUp><C-\\><C-n>',
          { noremap = true, silent = true, desc = 'Half page up' })
        vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-d>', 'i<C-PageDown><C-\\><C-n>',
          { noremap = true, silent = true, desc = 'Half page down' })
        -- Matches tui.json: home/end for first/last
        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gg', 'i<Home><C-\\><C-n>',
          { noremap = true, silent = true, desc = 'Jump to first message' })
        vim.api.nvim_buf_set_keymap(bufnr, 'n', 'G', 'i<End><C-\\><C-n>',
          { noremap = true, silent = true, desc = 'Jump to last message' })
      else
        local delete_buffer_keymap = function(m, lhs)
          local keymaps = vim.api.nvim_buf_get_keymap(bufnr, m)
          for _, km in ipairs(keymaps) do
            if km.mode == m and km.lhs == lhs then
              vim.api.nvim_buf_del_keymap(bufnr, m, lhs)
            end
          end
        end
        delete_buffer_keymap('t', '<Esc>')
        delete_buffer_keymap('n', '<C-k>')
        delete_buffer_keymap('n', '<C-j>')
        delete_buffer_keymap('n', '<C-k>')
        delete_buffer_keymap('n', '<C-u>')
        delete_buffer_keymap('n', '<C-d>')
        delete_buffer_keymap('n', 'gg')
        delete_buffer_keymap('n', 'G')
      end
    end, 5000) -- Delay to let user start opencode process after entering terminal
  end,
})

-- Find the most recently active terminal buffer running OpenCode
local function find_opencode_terminal()
  -- First try the last terminal we entered
  if last_terminal_bufnr and vim.api.nvim_buf_is_valid(last_terminal_bufnr) then
    if vim.bo[last_terminal_bufnr].buftype == 'terminal' then
      local chan = get_terminal_channel(last_terminal_bufnr)
      if chan and is_opencode_running(chan) then
        return chan, last_terminal_bufnr
      end
    end
  end

  -- Fallback: search all buffers for any running OpenCode terminal
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buftype == 'terminal' then
      local chan = get_terminal_channel(bufnr)
      if chan and is_opencode_running(chan) then
        return chan, bufnr
      end
    end
  end

  return nil, nil
end

-- Send text to OpenCode terminal
vim.keymap.set('v', 'O', function()
  -- Get selected lines
  local start_line = vim.fn.line "'<"
  local end_line = vim.fn.line "'>"
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  if #lines == 0 then
    print 'No lines selected'
    return
  end

  -- Get filename
  local filename = vim.fn.expand '%:p'
  if filename == '' then
    filename = '[unnamed]'
  end

  -- Build the message with context header
  local context = string.format('File: %s (lines %d-%d)\n', filename, start_line, end_line)
  local text = context .. table.concat(lines, '\n') .. '\n'

  -- Find OpenCode terminal
  local chan, _ = find_opencode_terminal()
  if not chan then
    print 'No OpenCode terminal found'
    return
  end

  -- Send to terminal
  vim.fn.chansend(chan, text)
  print('Sent ' .. #lines .. ' lines from ' .. filename .. ' (' .. start_line .. '-' .. end_line .. ') to OpenCode')
end, { desc = 'Send selected lines to OpenCode' })
