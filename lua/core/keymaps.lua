vim.keymap.set('n', 'gl', function()
  vim.fn.setreg('+', vim.fn.expand '%')
end, { desc = 'Copy current file path' })

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
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

local resize_amount = 10
vim.keymap.set('n', '<C-W>>', function()
  vim.api.nvim_win_set_width(0, vim.api.nvim_win_get_width(0) + resize_amount)
end)
vim.keymap.set('n', '<C-W><', function()
  vim.api.nvim_win_set_width(0, vim.api.nvim_win_get_width(0) - resize_amount)
end)

vim.api.nvim_set_keymap('c', '<C-j>', '<C-n>', { noremap = false })
vim.api.nvim_set_keymap('c', '<C-k>', '<C-p>', { noremap = false })
vim.keymap.set('n', 'gf', OpenLink, { noremap = true, silent = true })
