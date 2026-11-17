return {
  {
    '13janderson/git-worktree.nvim',
    -- Disabled for now: its plugin script loads the persistence session at
    -- plugin-load time, before LSP is ready. Session restore now lives in
    -- session.lua. Re-enable only after removing that implicit persistence.load().
    cond = false,
    version = '^2',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope.nvim', 'folke/persistence.nvim' },
  },
}
