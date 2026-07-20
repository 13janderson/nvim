return {
  {
    "13janderson/harpoon2",
    branch = "harpoon2",
    event = "VimEnter",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require('harpoon')
      harpoon:setup {
        settings = {
          save_on_toggle = true,
          save_on_ui_close = true,
          tmux_autoclose_windows = false,
        },
      }
      vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
      vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
      -- Pseudo arrow keys for config
      vim.keymap.set("n", "<C-h>", function() harpoon:list():select(1) end)
      vim.keymap.set("n", "<C-b>", function() harpoon:list():select(2) end)
      vim.keymap.set("n", "<C-n>", function() harpoon:list():select(3) end)
      vim.keymap.set("n", "<C-m>", function() harpoon:list():select(4) end)
    end

  },
}
