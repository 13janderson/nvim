local rename_map = {}
return {
  {
    "13janderson/harpoon-float.nvim",
    dependencies = {
      "ThePrimeagen/harpoon",
      branch = "harpoon2"
    },
  },
  {
    "ThePrimeagen/harpoon",
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


      -- Toggle previous & next buffers stored within Harpoon list
      -- vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end)
      -- vim.keymap.set("n", "<C-S-N>", function() harpoon:list():next() end)

      -- Auto-commands to capture changes in buffer renames
      -- this can be used in conjunction with GRename to rename files
      -- and have those changes update in harpoon.
      vim.api.nvim_create_autocmd('BufFilePre', {
        desc = 'Capture old name of buffers before they were renamed.',
        pattern = { "*.*" },
        group = vim.api.nvim_create_augroup('HarpoonBufFilePre', { clear = true }),
        callback = function(e)
          -- Harpoon adds buffers relative to the cwd
          local current_name = vim.api.nvim_buf_get_name(e.buf)

          if not rename_map[e.buf] then
            local relative_current_name = current_name:gsub("^" .. vim.fn.getcwd() .. "/", "")
            rename_map[e.buf] = relative_current_name
          end
        end,
      })

      vim.api.nvim_create_autocmd('BufFilePost', {
        desc = 'Capture new name of buffers when they are renamed.',
        pattern = { "*.*" },
        group = vim.api.nvim_create_augroup('HarpoonBufFilePost', { clear = true }),
        callback = function(e)
          local harpoon_list = harpoon:list()

          -- Harpoon adds buffers relative to the cwd
          local new_name = vim.api.nvim_buf_get_name(e.buf)
          --
          local relative_newname = new_name:gsub("^" .. vim.fn.getcwd() .. "/", "")

          local relative_oldname = rename_map[e.buf]
          local harpoon_old, harpoon_old_idx = harpoon_list:get_by_value(relative_oldname)

          if harpoon_old_idx then
            local harpoon_new = vim.tbl_deep_extend("force", {}, harpoon_old)
            harpoon_new.value = relative_newname
            harpoon_list:replace_at(harpoon_old_idx, harpoon_new)
          end

          -- After we do this, delete all entries from the table
          -- This is needed in case buffer numbers are re-used later in the same session
          -- and to behaviour of BufFilePost event for new file over-writing the old one.
          -- Think this was happening when b1 was renamed to b2, we'd get b1->b2 then we'd get
          -- events for b2->b1 as well so this would undo itself.
          rename_map = {}
        end,
      })
    end
  },
}
