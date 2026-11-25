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

-- vim.keymap.set('n', '<leader>q', vim.diagnostic.setqflist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('n', '<C-Q>', toggle_qf, { desc = 'Open diagnostic [Q]uickfix list' })

vim.api.nvim_create_autocmd('VimLeavePre', {
  callback = function()
    -- close quickfix list if open
    if find_qf() ~= nil then
      vim.cmd 'cclose'
    end
  end,
})

-- vim.api.nvim_create_autocmd('QuickFixCmdPost', {
--   callback = function(_)
--     local qf = vim.fn.getqflist()
--     if #qf > 0 then
--       vim.cmd('cfirst!')
--       vim.cmd('e!')
--     end
--   end,
-- })
