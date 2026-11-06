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
    callback = function(_)
      if delay_ms then
        vim.defer_fn(run, delay_ms)
        return
      end
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

local SCRATCH_NAME = "__scratch__"
local SCRATCH_MIN_HEIGHT = 5
local SCRATCH_MAX_HEIGHT = 15
local SCRATCH_BOTTOM_PADDING = 2

local function scratch_height(bufnr)
  local lines = vim.api.nvim_buf_line_count(bufnr)
  local height = lines
  if lines >= SCRATCH_MIN_HEIGHT then
    height = height + SCRATCH_BOTTOM_PADDING
  end
  height = math.max(SCRATCH_MIN_HEIGHT, math.min(SCRATCH_MAX_HEIGHT, height))
  local available = math.max(1, vim.o.lines - vim.o.cmdheight - 2)
  return math.min(height, available)
end

local function resize_scratch(bufnr)
  local height = scratch_height(bufnr)
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    if vim.api.nvim_win_get_height(win) ~= height then
      pcall(vim.api.nvim_win_set_height, win, height)
    end
  end
end

vim.api.nvim_create_autocmd({ 'ExitPre', 'VimLeavePre' }, {
  group = vim.api.nvim_create_augroup('ScratchAutosave', { clear = true }),
  callback = function(args)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf):match(SCRATCH_NAME .. '$') then
        if vim.bo[buf].modified then
          vim.api.nvim_buf_call(buf, function()
            vim.cmd 'silent! write'
          end)
        end
        if args.event == 'VimLeavePre' then
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end
      end
    end
  end,
})

local function setup_scratch_resize(bufnr)
  if vim.b[bufnr].scratch_resize_autocmd then
    return
  end
  vim.b[bufnr].scratch_resize_autocmd = true
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'TextChangedP', 'InsertLeave' }, {
    buffer = bufnr,
    callback = function()
      vim.schedule(function()
        resize_scratch(bufnr)
      end)
    end,
  })
end

function _G.ToggleScratch()
  local scratch_path = vim.fn.fnamemodify(SCRATCH_NAME, ':p')
  local existing_bufnr = nil

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(buf):match(SCRATCH_NAME .. "$") then
      existing_bufnr = buf
      break
    end
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == existing_bufnr then
      vim.api.nvim_win_close(win, false)
      return
    end
  end

  local bufnr = existing_bufnr or vim.fn.bufadd(scratch_path)
  vim.fn.bufload(bufnr)
  vim.bo[bufnr].buftype = ''
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].buflisted = false
  vim.bo[bufnr].bufhidden = 'hide'
  setup_scratch_resize(bufnr)

  local height = scratch_height(bufnr)
  local winnr = 0

  if vim.api.nvim_buf_get_name(0) ~= "" then
    winnr = vim.api.nvim_open_win(bufnr, false, {
      split = 'above',
      win = 0,
      height = height,
    })
  else
    vim.api.nvim_set_current_buf(bufnr)
    resize_scratch(bufnr)
  end

  vim.api.nvim_set_current_win(winnr)
end
