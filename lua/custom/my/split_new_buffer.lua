local M = {}

local EMPTY_BY_DEFAULT = false

if vim.g.split_new_buffer_empty == nil then
  vim.g.split_new_buffer_empty = EMPTY_BY_DEFAULT
end

local pending = nil
local inflight = {}

local function is_normal(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == '' and vim.api.nvim_buf_get_name(buf) ~= ''
end

local function flush(win)
  local state = inflight[win]
  inflight[win] = nil
  if not vim.g.split_new_buffer_empty then
    return
  end
  if not state or state.got_buf then
    return
  end
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  if vim.api.nvim_win_get_buf(win) ~= state.src or not is_normal(state.src) then
    return
  end
  vim.api.nvim_win_set_buf(win, vim.api.nvim_create_buf(true, false))
end

local group = vim.api.nvim_create_augroup('SplitNewBuffer', { clear = true })

vim.api.nvim_create_autocmd('WinNewPre', {
  group = group,
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    pending = is_normal(buf) and { src = buf } or nil
    vim.schedule(function()
      pending = nil
    end)
  end,
})

vim.api.nvim_create_autocmd('WinNew', {
  group = group,
  callback = function()
    if not pending then
      return
    end
    local win = vim.api.nvim_get_current_win()
    inflight[win] = { src = pending.src, got_buf = false }
    pending = nil
    vim.schedule(function()
      flush(win)
    end)
  end,
})

vim.api.nvim_create_autocmd('BufWinEnter', {
  group = group,
  callback = function()
    local state = inflight[vim.api.nvim_get_current_win()]
    if state then
      state.got_buf = true
    end
  end,
})

return M
