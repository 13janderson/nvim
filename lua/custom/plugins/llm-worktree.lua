return {
  -- "13janderson/llm-worktree.nvim",
  dir = "~/projects/plugins/claude-worktree.nvim",
  config = function()
    local wt = require "claude-worktree"
    wt.setup()
  end
}
