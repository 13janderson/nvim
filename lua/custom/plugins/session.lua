-- Session management
return {
  'folke/persistence.nvim',
  opts = {},
  -- this gets in the way for tmp directories. e.g. when editing crontabs, editing opencode prompts.
  cond = not (vim.startswith(vim.fn.getcwd(), '/tmp')
    or vim.startswith(vim.fn.expand('%:p'), '/tmp')),
}
