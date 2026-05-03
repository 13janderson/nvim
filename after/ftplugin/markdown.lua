local spellfile = vim.fn.stdpath("config") .. "/spell.en-utf8.add"

vim.schedule(function()
  -- Add good word with zg
  -- Add bad word with zw
  vim.api.nvim_set_option_value("spellfile", spellfile, { scope = "local" })
  vim.api.nvim_set_option_value("spell", true, { scope = "local" })
  vim.api.nvim_set_option_value("spelllang", "en_gb", { scope = "local" })
end)

vim.fn.setreg("n", 'a[]i[]i')

-- Workaround for Neovim 0.12 treesitter range error with render-markdown
-- Ensure the parser is attached before render-markdown tries to use it
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  once = true,
  callback = function(args)
    -- Small delay to ensure treesitter parser is fully initialized
    vim.defer_fn(function()
      local ok, parser = pcall(vim.treesitter.get_parser, args.buf)
      if ok and parser then
        -- Force parser parse to ensure it's ready
        pcall(function() parser:parse() end)
      end
    end, 10)
  end,
})
