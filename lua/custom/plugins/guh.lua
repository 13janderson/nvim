local pre_013 = vim.fn.has('nvim-0.13') == 0

return {
  'justinmk/guh.nvim',
  -- Latest guh requires Neovim 0.13+ (vim.async). Pin the last pre-async
  -- commit on 0.12; use main once on 0.13+.
  commit = pre_013 and '928d673f9ced9fa53d5c5620dba48458e9f139bb' or nil,
  config = function()
    vim.keymap.set('n', 'Ug', '<cmd>Guh .<cr>', { desc = 'GitHub: current target' })
    vim.keymap.set('n', '<leader>o', '<cmd>Guh<cr>', { desc = 'GitHub: status / notifications' })
  end,
}
