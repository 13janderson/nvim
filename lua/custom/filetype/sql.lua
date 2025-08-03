-- Match against all files in this case as a workaround for vim-dadbod not creating buffers with names that end with .sql
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = { "*" },
  group = vim.api.nvim_create_augroup("SQLFile", {
    clear = true,
  }),
  callback = function(_)
    if vim.bo.filetype == "sql" or vim.bo.filetype == "mysql" then
      vim.bo.commentstring = '-- %s'
    end
  end,
})

return {}
