vim.api.nvim_create_autocmd("BufEnter", {
  pattern = { "*.py" },
  group = vim.api.nvim_create_augroup("PythonFile", {
    clear = true,
  }),
  callback = function(_)
    -- Format string macro @p on current word
    -- While this is horrible to look at, it just works for python
    -- and is much easier to implement it this way.
    -- Also allows us to make use of macros as opposed to keybindings 
    vim.fn.setreg("p", 'yiwoprint()if""hpa: {}hp_')
  end,
})

return {}
