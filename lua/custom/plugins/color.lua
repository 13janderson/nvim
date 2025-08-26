---@param colour "rosepine" | "tokionight" | "onedark" | "catppuccin" | "oxocarbon" | "everforest" | nil
function ColourMyPencils(colour)
  -- TODO refactor this shite, wrap setting colour in pcall maybe?
  if colour == "rosepine" then
    vim.cmd.colorscheme 'rose-pine-moon'
  elseif colour == "tokionight" then
    vim.cmd.colorscheme 'tokyonight-storm'
  elseif colour == "onedark" then
    vim.cmd.colorscheme 'onedark'
  elseif colour == "catppuccin" then
    vim.cmd.colorscheme 'catppuccin'
  elseif colour == "oxocarbon" then
    vim.cmd.colorscheme 'oxocarbon'
  elseif colour == "everforest" then
    vim.cmd.colorscheme 'everforest'
  else
    -- Default
    vim.cmd.colorscheme 'rose-pine-moon'
  end
end

function ColourMyLines()
  vim.cmd [[
          highlight LineNr guifg=#ff8800 gui=bold
          highlight CursorLineNr guifg=#ff8800 gui=bold
          " highlight DiffAdd    guifg=#2ECC71 gui=bold
          " highlight DiffDelete guifg=#D75A49 gui=bold
      ]]
  vim.cmd [[
          highlight LineNr guifg=#ff8800 gui=bold
          highlight CursorLineNr guifg=#ff8800 gui=bold
      ]]
end

vim.api.nvim_create_autocmd({ "BufEnter" }, {
  pattern = "*",
  group = vim.api.nvim_create_augroup('LineColors', { clear = true }),
  callback = ColourMyLines
})

local rosepine = { -- You can easily change to a different colorscheme.
  -- Change the name of the colorscheme plugin below, and then
  -- change the command in the config to whatever the name of that colorscheme is.
  --
  -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
  'rose-pine/neovim',
  priority = 1000, -- Make sure to load this before all the other start plugins.
  config = function()
    ---@diagnostic disable-next-line: missing-fields
    require('rose-pine').setup {
      disable_background = true,
      styles = {
        italic = false,
        bold = false,
      },
    }
    ColourMyPencils("rosepine")
  end,
}

local tokionight = {
  -- You can easily change to a different colorscheme.
  -- Change the name of the colorscheme plugin below, and then
  -- change the command in the config to whatever the name of that colorscheme is.
  --
  -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
  'folke/tokyonight.nvim',
  priority = 1000, -- Make sure to load this before all the other start plugins.
  config = function()
    ---@diagnostic disable-next-line: missing-fields
    require('tokyonight').setup {
      transparent = true,
      styles = {
        italic = false,
        bold = false,
      },
    }
  end,
}

local onedark = {
  'navarasu/onedark.nvim',
  priority = 1000, -- Make sure to load this before all the other start plugins.
  config = function()
    ---@diagnostic disable-next-line: missing-fields
    require('onedark').setup {
      transparent = false,
      disable_background = false,
    }
  end,
}

local catppuccin = {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      flavour = "frappe", -- or "latte", "frappe", "macchiato"
      transparent_background = true,
    })
  end,
}

local oxocarbon = {
  "nyoom-engineering/oxocarbon.nvim",
  lazy = false,
  priority = 1000,
  transparent_background = true,
}

local everforest = {
  "sainnhe/everforest",
  lazy = false,
  priority = 1000,
  config = function()
    vim.g.everforest_background = "soft" -- "soft" "medium", "hard"
    vim.g.everforest_transparent_background = true
  end,
}

local oil_ex = require "oil_filexplorer"
local ex = oil_ex:new()

-- Try to make editor more VSCodey, for ease of co-workers
-- this function can be used as a toggle using a global variable vscode
local function vs_code()
  local vs_code_on = vim.g.vscode or false
  if vs_code_on then
    ex:kill()
    ex = oil_ex:new()
    vim.cmd "se relativenumber"
    -- ColourMyPencils()
    vim.g.vscode = false
  else
    ex:up()
    -- ColourMyPencils("tokionight")
    vim.cmd "se norelativenumber"
    vim.g.vscode = true
  end
  ColourMyLines()
end

vim.api.nvim_create_user_command("VSCode", vs_code, {})
vim.keymap.set('n', '<leader>vs', vs_code, { desc = 'Toggle VSCode display with vs_code function.' })

return {
  rosepine,
  tokionight,
  onedark,
  catppuccin,
  oxocarbon,
  everforest,
}
