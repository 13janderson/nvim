vim.keymap.set('n', 'gl', function()
  vim.fn.setreg('+', vim.fn.expand '%')
end, { desc = 'Copy current file path' })

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('n', '<leader>sp', function()
  vim.wo.spell = not vim.wo.spell
  vim.notify('spell ' .. (vim.wo.spell and 'on' or 'off'))
end, { desc = 'Toggle spell' })
vim.keymap.set('n', '<CR>', '<NOP>', { noremap = true, silent = true })

vim.keymap.set('t', '<C-]><C-n>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('t', '<C-]>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

vim.keymap.set('n', '<C-f>', '<cmd>silent !tmux neww tmux-sessionizer.sh<CR>')
vim.keymap.set('n', '<leader>x', ToggleScratch)
vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]])
vim.keymap.set('n', '<leader>Y', 'ggVG"+y<C-O>')
vim.keymap.set('n', '-', ':Oil<CR>')
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')
vim.keymap.set('x', '<leader>p', [["_dP]])
vim.keymap.set('n', '<C-p>', '<C-^>', { noremap = false, silent = true })

-- Resizing
vim.keymap.set('n', '<C-W>>', '10<C-W>>')
vim.keymap.set('n', '<C-W><', '10<C-W><')
vim.keymap.set('n', '<C-W>+', '5<C-W>+')
vim.keymap.set('n', '<C-W>-', '5<C-W>-')

vim.api.nvim_set_keymap('c', '<C-j>', '<C-n>', { noremap = false })
vim.api.nvim_set_keymap('c', '<C-k>', '<C-p>', { noremap = false })
vim.keymap.set('n', 'gf', OpenLink, { noremap = true, silent = true })

-- Tabs
vim.keymap.set('n', '<C-t>o', function()
  vim.cmd 'tabm 0'
  local tabs = #vim.api.nvim_list_tabpages()
  -- print("tabs", tabs)
  for i = tabs, 2, -1 do
    vim.cmd('tabc ' .. i)
    -- print('tabc ' .. i)
  end
end)
