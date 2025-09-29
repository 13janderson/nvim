-- Gemini
local _ = {
  'kiddos/gemini.nvim',
  opts = {
    completion_delay = 400,
    instruction = {
      -- Don't like the way the menu system is done here... probs not going to use this
      menu_key = "<C-G>"
    }
  },
  cond = not string.find(vim.fn.getcwd(), "CVS")
}

local minuet = {
  'milanglacier/minuet-ai.nvim',
  config = function()
    require('minuet').setup {
      -- -- Your configuration options here
      provider = 'gemini',
      provider_options = {
        gemini = {
          model = "gemini-2.5-flash-lite",
        }
      }
    }
    vim.keymap.set("n", "<leader>g", function()
      local muet = require "minuet"
      local cmp_enabled = muet.config.cmp.enable_auto_complete
      if cmp_enabled then
        print("Minuet cmp disabled")
      else
        print("Minuet cmp enabled")
      end
      muet.config.cmp.enable_auto_complete = not cmp_enabled
    end)

    -- Nice to know when this is loaded and when it isnt.
    print("GEMINI IS RUNNING")
  end,
  dependencies = {
    'nvim-lua/plenary.nvim',
    -- optional, if you are using virtual-text frontend, nvim-cmp is not
    -- required.
    'hrsh7th/nvim-cmp',
    -- optional, if you are using virtual-text frontend, blink is not required.
    -- { 'Saghen/blink.cmp' },
  },
  cond = not string.find(vim.fn.getcwd(), "CVS") and false
}


return minuet
