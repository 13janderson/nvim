vim.keymap.set('n', '<M-l>', 'gt')
vim.keymap.set('n', '<M-h>', 'gT')

vim.keymap.set('n', '<M-n>', function()
  vim.cmd 'tabe'
end)

vim.keymap.set('n', '<M-c>', function()
  vim.cmd 'tabc'
end)

-- I could be the goat
for i = 1, 10, 1 do
  vim.keymap.set('n', string.format('%dgt', i), function() vim.cmd(string.format('tabn %d', i)) end)
end
