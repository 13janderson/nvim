vim.fn.setreg("p", 'yiw}kofmt.Printf()i""hpa: %s\\nla, paok_')
vim.fn.setreg("o", 'yiwofmt.Printf()i""hpa: %s\\nla, pa_')
vim.fn.setreg("O", 'yiwOfmt.Printf()i""hpa: %s\\nla, pa_')
vim.fn.setreg("n", 'yiwoif pa != nil{\n}')

vim.keymap.set('n', '<leader>dt', function()
  require('dap-go').debug_test()
end, { buffer = true, desc = 'DAP: Debug nearest Go test' })
