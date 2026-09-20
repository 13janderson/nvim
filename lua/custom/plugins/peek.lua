return {
  'toppair/peek.nvim',
  build = 'deno task --quiet build:fast',
  config = function()
    require('peek').setup {
      app = 'browser',
      auto_load = true,
    }

    vim.api.nvim_create_user_command('PeekOpen', require('peek').open, {})
    vim.api.nvim_create_user_command('PeekClose', require('peek').close, {})

    vim.api.nvim_create_autocmd('VimLeave', {
      pattern = { '*.md' },
      group = vim.api.nvim_create_augroup('PeekCloseOnLeave', { clear = true }),
      callback = function()
        local peek = require 'peek'
        if peek.is_open() then
          peek.close()
        end
      end,
    })

    vim.api.nvim_create_user_command('Preview', function()
      local peek = require 'peek'
      if peek.is_open() then
        return
      end
      peek.close()
      if vim.bo.filetype == 'markdown' then
        peek.open()
        print 'Markdown preview opened'
      else
        print 'Filetype must be markdown'
      end
      Clear(500)
    end, {})
  end,
}
