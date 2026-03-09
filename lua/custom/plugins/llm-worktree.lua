return {
  "13janderson/llm-worktree.nvim",
  branch = 'claude',
  -- dir = "~/projects/plugins/claude-worktree.nvim/.git/cw-cw-1773013491",
  config = function()
    local wt = require "claude-worktree"
    wt.setup()
  end
}
