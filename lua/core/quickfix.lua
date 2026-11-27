-- quickfix

local function find_qf()
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      vim.cmd 'cclose'
      return win
    end
  end
  return nil
end

local function toggle_qf()
  local qf = find_qf()
  if qf == nil then
    vim.cmd 'copen'
  end
end

local function toggle_diagnostics()
  local qf = find_qf()
  if qf == nil then
    vim.diagnostic.setqflist()
  end
end



vim.keymap.set('n', '<leader>q', toggle_diagnostics,
  { desc = 'Toggle diagnostic [Q]uickfix list' })
vim.keymap.set('n', '<C-Q>', toggle_qf, { desc = 'Toggle [Q]uickfix list' })

vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = function()
    -- close quickfix list if open
    if find_qf() ~= nil then
      vim.cmd 'cclose'
    end
  end,
})
