vim.keymap.set('n', '<M-l>', 'gt')
vim.keymap.set('n', '<M-h>', 'gT')
vim.keymap.set('n', '<M-c>', function()
  vim.cmd 'tabc'
end)
vim.keymap.set('n', '<M-e>', function()
  vim.cmd 'tabe'
end)

vim.keymap.set('n', '<M-p>', 'g<Tab>')

-- I could be the goat
for i = 1, 10, 1 do
  vim.keymap.set('n', string.format('<M-%d>', i), function() vim.cmd(string.format('tabn %d', i)) end)
end
