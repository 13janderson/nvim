-- Session management
return {
  'folke/persistence.nvim',
  config = function()
    require('persistence').setup {}

    -- git-worktree used to load the persistence session as a side effect of
    -- its plugin script. With it disabled, restore explicitly.
    vim.api.nvim_create_autocmd('VimEnter', {
      callback = function()
        vim.schedule(function()
          if vim.fn.argc() == 0 and vim.fn.line2byte '$' == -1 then
            require('persistence').load()
          end
        end)
      end,
    })
  end,
  -- this gets in the way for tmp directories. e.g. when editing crontabs, editing opencode prompts.
  cond = not (vim.startswith(vim.fn.getcwd(), '/tmp')
    or vim.startswith(vim.fn.expand('%:p'), '/tmp')),
}
