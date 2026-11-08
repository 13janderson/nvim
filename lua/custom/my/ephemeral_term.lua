local M = {}

local term_bufs = {}

local function buf_valid(buf)
  return buf and buf > 0 and vim.api.nvim_buf_is_valid(buf)
end

local function wipe_buf(buf)
  if not buf_valid(buf) then
    return
  end

  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    pcall(vim.api.nvim_win_close, win, true)
  end

  if buf_valid(buf) then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

local function open(direction)
  if direction == 'vertical' then
    vim.cmd 'rightbelow vsplit'
  else
    vim.cmd 'aboveleft split'
  end

  vim.cmd 'terminal'

  local buf = vim.api.nvim_get_current_buf()
  term_bufs[buf] = true

  vim.bo[buf].buflisted = false
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false

  vim.keymap.set('n', 'q', function()
    wipe_buf(buf)
  end, { buffer = buf, desc = 'Close ephemeral terminal' })

  vim.api.nvim_create_autocmd('BufWipeout', {
    buffer = buf,
    once = true,
    callback = function()
      term_bufs[buf] = nil
    end,
  })

  vim.api.nvim_create_autocmd('TermClose', {
    buffer = buf,
    once = true,
    callback = function()
      vim.schedule(function()
        wipe_buf(buf)
      end)
    end,
  })
end

function M.horizontal()
  open 'horizontal'
end

function M.vertical()
  open 'vertical'
end

vim.keymap.set('n', '<leader>es', M.horizontal, { desc = 'Terminal: Ephemeral horizontal' })
vim.keymap.set('n', '<leader>ev', M.vertical, { desc = 'Terminal: Ephemeral vertical' })

vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = function()
    for buf in pairs(term_bufs) do
      if buf_valid(buf) then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
    term_bufs = {}
  end,
})

return M
