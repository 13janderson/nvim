vim.api.nvim_create_autocmd("BufEnter", {
  pattern = { "*.go" },
  group = vim.api.nvim_create_augroup("GoFile", {
    clear = true,
  }),
  callback = function(_)
    vim.fn.setreg("p", 'yiwofmt.Printf()i""hpa: %s\\nla, pa_')
  end,
})

return {}
