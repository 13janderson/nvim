return {
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
    vim.cmd.colorscheme 'rose-pine-moon'
    vim.api.nvim_set_hl(0, 'LineNr', { fg = '#ff8800', bold = true })
  end,
}
