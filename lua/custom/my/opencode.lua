vim.api.nvim_create_autocmd('TermOpen', {
  callback = function()
    vim.defer_fn(function()
      local bufnr = vim.api.nvim_get_current_buf()

      -- Terminal buffer keymaps for easier navigation
      vim.api.nvim_buf_set_keymap(bufnr, 't', '<Esc>', '<C-\\><C-n>',
        { noremap = true, silent = true, desc = 'Exit terminal mode' })
      vim.api.nvim_buf_set_keymap(bufnr, 't', '<C-[>', '<C-\\><C-n>',
        { noremap = true, silent = true, desc = 'Exit terminal mode' })
      -- Normal mode scrolling in terminal (send to opencode)
      -- Matches tui.json: shift+k scrolls up, shift+j scrolls down
      vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-k>', 'i<PageUp><C-\\><C-n>',
        { noremap = true, silent = true, desc = 'Scroll up' })
      vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-j>', 'i<PageDown><C-\\><C-n>',
        { noremap = true, silent = true, desc = 'Scroll down' })
      -- Matches tui.json: ctrl+b/f for half page scrolling
      vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-u>', 'i<C-PageUp><C-\\><C-n>',
        { noremap = true, silent = true, desc = 'Half page up' })
      vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-d>', 'i<C-PageDown><C-\\><C-n>',
        { noremap = true, silent = true, desc = 'Half page down' })
      -- Matches tui.json: home/end for first/last
      vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gg', 'i<Home><C-\\><C-n>',
        { noremap = true, silent = true, desc = 'Jump to first message' })
      vim.api.nvim_buf_set_keymap(bufnr, 'n', 'G', 'i<End><C-\\><C-n>',
        { noremap = true, silent = true, desc = 'Jump to last message' })
    end, 100) -- Small delay to let process start
  end,
})
