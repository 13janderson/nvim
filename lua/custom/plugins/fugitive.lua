return {
  'tpope/vim-fugitive',
  config = function(_)
    -- Use navigating merge conflict defaults for now [c for previous ]c for next conflict
    -- Set keybindings for resolving merge conflicts
    vim.keymap.set("n", "<leader>(", ":diffget //2<CR>")
    vim.keymap.set("n", "<leader>)", ":diffget //3<CR>")

    local function fugitive_commit()
      DoOnNewBuffer(function()
        -- Only set the lines if a new buffer is made within 2 seconds
        vim.api.nvim_buf_set_lines(0, 0, 1, true, { "feat: " })
      end, 2000)
      vim.cmd("G commit -a --no-verify")
    end
    vim.keymap.set("n", "<leader>co", fugitive_commit)

    vim.keymap.set("n", "<leader>cp", function()
      fugitive_commit()

      vim.api.nvim_create_autocmd("BufWinLeave", {
        pattern = "COMMIT_EDITMSG",
        callback = function()
          vim.schedule(function() vim.cmd("G push") end)
        end,
        once = true
      })
      -- DoOnBufferClose(function()
      --   vim.cmd("G push")
      -- end, 5000)
    end)

    vim.keymap.set("n", "[c", "[czz")
    vim.keymap.set("n", "]c", "]czz")
  end
}
