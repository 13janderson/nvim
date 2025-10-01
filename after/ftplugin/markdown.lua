local spellfile = vim.fn.stdpath("config") .. "/spell.en-utf8.add"

vim.schedule(function()
  -- Add good word with zg
  -- Add bad word with zw
  vim.api.nvim_set_option_value("spellfile", spellfile, { scope = "local" })
  vim.api.nvim_set_option_value("spell", true, { scope = "local" })
  vim.api.nvim_set_option_value("spelllang", "en_gb", { scope = "local" })
end)
