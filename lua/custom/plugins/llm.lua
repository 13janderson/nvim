-- Gemini
local gemini = {
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
    }
    vim.keymap.set("n", "<leader>g", ":Minuet cmp toggle<CR>")
  end,
  dependencies = {
    'nvim-lua/plenary.nvim',
    -- optional, if you are using virtual-text frontend, nvim-cmp is not
    -- required.
    'hrsh7th/nvim-cmp',
    -- optional, if you are using virtual-text frontend, blink is not required.
    -- { 'Saghen/blink.cmp' },
  },
  cond = not string.find(vim.fn.getcwd(), "CVS")
}

return minuet
