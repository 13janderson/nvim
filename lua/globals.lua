function _G.Clear(delay_ms)
  delay_ms = delay_ms or 250
  local timer = vim.uv.new_timer()
  timer:start(delay_ms, 0, vim.schedule_wrap(function()
    vim.api.nvim_echo({ { "" } }, false, {})
  end))
end

---@param prefix ?string
---@param tbl table
function _G.PrintPrefix(prefix, tbl)
  print(prefix or "", vim.inspect(tbl))
end

---@param tbl table
function _G.Print(tbl)
  print(vim.inspect(tbl))
end

-- Run a function when the next buffer is loaded.
-- This is a one-time function to run striclty on the next buffer loading
function _G.DoOnNewBuffer(run, timeout_ms)
  if not timeout_ms then
    timeout_ms = 5000
  end

  local augroup_name = "OneShotCommandNewBuffer"
  vim.api.nvim_create_autocmd("BufEnter", {
    callback = run,
    group = vim.api.nvim_create_augroup(augroup_name, { clear = true }),
    once = true, -- this command clears itself upon completion
  })
  -- Remove the autocmd after timeout
  vim.defer_fn(function()
    vim.api.nvim_del_augroup_by_name(augroup_name)
  end, timeout_ms)
end

-- Run a function when the next buffer is closed. Takes optional delay in delay_ms
-- which will be awaited before running the callback if provided.
-- This is a one-time function
function _G.DoOnBufferClose(run, timeout_ms, delay_ms)
  if not timeout_ms then
    timeout_ms = 5000
  end

  local augroup_name = "OneShotCommandCloseBuffer"
  vim.api.nvim_create_autocmd("BufLeave", {
    callback = function(e)
      if delay_ms then
        vim.defer_fn(run, delay_ms)
        return
      end
      print "running function without defer"
      vim.schedule(run)
    end,
    group = vim.api.nvim_create_augroup(augroup_name, { clear = true }),
    once = true, -- this command clears itself upon completion
  })
  -- Remove the autocmd after timeout
  vim.defer_fn(function()
    vim.api.nvim_del_augroup_by_name(augroup_name)
  end, timeout_ms)
end

-- Does not refresh the contents of the buffer but rather forces the contents to be reloaded
-- in the same buffer. This is achieved by creating a temporary buffer and then switching back
-- to the original.
function _G.ReloadCurentBuffer()
  local init_buf_nr = vim.api.nvim_get_current_buf()
  local scratch_buf_nr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(scratch_buf_nr)
  vim.defer_fn(function()
    vim.api.nvim_set_current_buf(init_buf_nr)
    vim.api.nvim_buf_delete(scratch_buf_nr, {})
  end, 100)
end

-- Open links under cursor in browser
function _G.OpenLink()
  local url = vim.fn.expand('<cfile>') -- word/file under cursor
  if url:match('^https?://') then
    -- macOS: "open"
    -- Linux: "xdg-open"
    -- Windows (WSL): "wslview" or "cmd.exe /c start"
    local browser = vim.env.BROWSER
    if browser == nil then
      print(string.format("Not opening %s since $BROWSER not set.", browser))
      return
    end
    print(string.format("Opening %s with %s", browser, url))
    vim.fn.jobstart({ browser, url }, { detach = true })
  else
    -- Fallback to normal gf behavior
    vim.cmd('normal! gf')
  end
end

function _G.OpenScratch()
  local bufnr = vim.api.nvim_create_buf(false, true)
  local winnr = 0

  if vim.api.nvim_buf_get_name(0) ~= "" then
    winnr = vim.api.nvim_open_win(bufnr, false, {
      split = 'left',
      win = 0
    })
  else
    vim.api.nvim_set_current_buf(bufnr)
  end

  vim.api.nvim_set_current_win(winnr)
end
