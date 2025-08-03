vim.api.nvim_create_autocmd("BufEnter", {
  pattern = { "*.lua" },
  group = vim.api.nvim_create_augroup("LuaFile", {
    clear = true,
  }),
  callback = function(_)
    -- Format string macro @p on current word
    vim.fn.setreg("p", 'yiwoprint()i""hpf"a, p_')
  end,
})
return {}
