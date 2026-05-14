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

vim.api.nvim_create_autocmd('TermEnter', {
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local chan = get_terminal_channel(bufnr)

    if not chan then
      print 'No terminal channel found'
      return
    end

    vim.defer_fn(function()
      if is_opencode_running(chan) then
        -- print 'Setting OpenCode keymaps'

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
        -- print 'Unsetting OpenCode keymaps'
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
  local bufs = vim.api.nvim_list_bufs()
  -- Iterate in reverse to find most recently used
  for i = #bufs, 1, -1 do
    local bufnr = bufs[i]
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
vim.keymap.set("v", "<leader>oc", function()
  -- Get selected lines
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  if #lines == 0 then
    print("No lines selected")
    return
  end

  -- Get filename
  local filename = vim.fn.expand('%:p')
  if filename == '' then
    filename = '[unnamed]'
  end

  -- Build the message with context header
  local context = string.format("File: %s (lines %d-%d)\n", filename, start_line, end_line)
  local text = context .. table.concat(lines, "\n") .. "\n"

  -- Find OpenCode terminal
  local chan, bufnr = find_opencode_terminal()
  if not chan then
    print("No OpenCode terminal found")
    return
  end

  -- Send to terminal
  vim.fn.chansend(chan, text)
  print("Sent " .. #lines .. " lines from " .. filename .. " (" .. start_line .. "-" .. end_line .. ") to OpenCode")
end, { desc = "Send selected lines to OpenCode" })
