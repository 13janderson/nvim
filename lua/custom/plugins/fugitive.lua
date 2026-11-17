local function git_lines(args)
  local lines = vim.fn.systemlist(vim.list_extend({ 'git' }, args))
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return lines
end

local function default_branch()
  local remotes = git_lines { 'remote' }
  if not remotes or #remotes == 0 then
    return nil
  end

  -- Clones normally retain this local symbolic ref, avoiding a network call.
  for _, remote in ipairs(remotes) do
    local head = git_lines { 'symbolic-ref', '--quiet', '--short', 'refs/remotes/' .. remote .. '/HEAD' }
    if head and head[1] then
      return head[1]:match '^[^/]+/(.+)$' or head[1]
    end
  end

  -- Fall back to Git's cached remote metadata for repositories without the ref.
  for _, remote in ipairs(remotes) do
    local details = git_lines { 'remote', 'show', '-n', remote }
    if details then
      for _, line in ipairs(details) do
        local branch = line:match '^%s*HEAD branch:%s*(.+)%s*$'
        if branch and branch ~= '(unknown)' then
          return branch
        end
      end
    end
  end

  return nil
end

--- Run a git command without blocking the editor and report the result.
local function run_git(args, label)
  vim.notify('git ' .. label .. '…', vim.log.levels.INFO, { title = 'git' })

  vim.system(vim.list_extend({ 'git' }, args), {
    text = true,
    env = { GIT_TERMINAL_PROMPT = '0' },
  }, function(res)
    vim.schedule(function()
      local output = vim.trim((res.stdout or '') .. (res.stderr or ''))
      local ok = res.code == 0
      local msg = output ~= '' and output
        or ('git ' .. label .. (ok and ' succeeded' or (' failed (' .. tostring(res.code) .. ')')))
      if #msg > 500 then
        msg = msg:sub(1, 500) .. '…'
      end
      vim.notify(msg, ok and vim.log.levels.INFO or vim.log.levels.ERROR, { title = 'git ' .. label })
    end)
  end)
end

local function async_pull()
  -- --no-edit keeps a merge from trying to open an editor in the background.
  run_git({ 'pull', '--no-edit' }, 'pull')
end

local function guarded_push(command)
  local branch = git_lines { 'branch', '--show-current' }
  local current_branch = branch and branch[1]
  local protected_branch = default_branch()

  if not current_branch or current_branch == '' then
    vim.notify('Unable to determine the current Git branch; push cancelled.', vim.log.levels.ERROR)
    return
  end

  if not protected_branch then
    vim.notify('Unable to determine the repository default branch; push cancelled.', vim.log.levels.ERROR)
    return
  end

  if current_branch == protected_branch then
    vim.notify('Push cancelled: pushing directly to ' .. protected_branch .. ' is disabled.', vim.log.levels.WARN)
    return
  end

  local args = type(command) == 'table' and command or vim.split(command or 'push', ' ', { trimempty = true })
  run_git(args, 'push')
end

return {
  {
    'tpope/vim-fugitive',
    dependencies = {
      'justinmk/vim-ug',
    },
    config = function(_)
      -- Use navigating merge conflict defaults for now [c for previous ]c for next conflict
      -- Set keybindings for resolving merge conflicts
      vim.keymap.set({ 'n', 'v' }, '<leader>(', ':diffget //2<CR>')
      vim.keymap.set({ 'n', 'v' }, '<leader>)', ':diffget //3<CR>')
      -- vim.keymap.set({ 'n', 'v' }, '<leader>(', 'd2o')
      -- vim.keymap.set({ 'n', 'v' }, '<leader>)', 'd3o')

      local function fugitive_commit()
        DoOnNewBuffer(function()
          -- Only set the lines if a new buffer is made within 2 seconds
          vim.api.nvim_buf_set_lines(0, 0, 1, true, { 'feat: ' })
        end, 2000)
        vim.cmd 'G commit -a --no-verify'
      end
      vim.keymap.set('n', '<leader>co', fugitive_commit)

      vim.keymap.set('n', '<leader>cp', function()
        fugitive_commit()

        vim.api.nvim_create_autocmd('BufWinLeave', {
          pattern = 'COMMIT_EDITMSG',
          callback = function()
            vim.schedule(function()
              guarded_push()
            end)
          end,
          once = true,
        })
      end)

      -- Diff viewing keymaps
      -- vim-ug's <C-n>/<C-p> hunk navigation is just a gitsigns wrapper when
      -- not in diff mode, but <C-n>/<C-p> are repurposed below. Call gitsigns
      -- directly so these keep working independently.
      local function nav_hunk(direction)
        return function()
          if vim.wo.diff then
            vim.cmd('normal! ' .. (direction == 'next' and ']c' or '[c'))
            return
          end

          local ok, gitsigns = pcall(require, 'gitsigns')
          if not ok then
            return
          end

          local nav = direction == 'next' and gitsigns.next_hunk or gitsigns.prev_hunk
          nav({ wrap = false }, function()
            vim.cmd 'normal! zz'
          end)
        end
      end

      vim.keymap.set('n', ']c', nav_hunk 'next', { desc = 'Next hunk' })
      vim.keymap.set('n', '[c', nav_hunk 'prev', { desc = 'Previous hunk' })

      -- Diffing uses vim-ug's built-in Ud / [count]Ud.

      -- git log
      -- vim.keymap.set('n', 'Ul', function()
      --   vim.cmd 'G log'
      -- end)

      -- -- git log --oneline
      -- vim.keymap.set('n', '1Ul', function()
      --   vim.cmd 'G log --oneline'
      -- end)

      -- git log --oneline for current file
      -- vim.keymap.set('n', '1UL', function()
      --   vim.cmd 'G log --oneline %'
      -- end)

      -- git log for current file
      -- vim.keymap.set('n', 'UL', function()
      --   vim.cmd 'G log %'
      -- end)
    end,
  },
  {
    'justinmk/vim-ug',
    config = function()
      -- keymap overrides
      vim.keymap.set('n', '<c-p>', '<c-^>', { noremap = false, silent = true })
      local capture = require "custom.my.capture"
      vim.keymap.set('n', '<C-n>', capture.open, { desc = "Capture to today's daily note" })

      local push = function()
        guarded_push 'push --no-verify'
      end

      vim.keymap.set('n', 'Up', push, { desc = 'Git: push' })
      vim.keymap.set('n', 'UP', async_pull, { desc = 'Git: pull' })

      vim.keymap.set('n', 'Uo', '<cmd>G checkout -<cr>', { desc = 'Git: previous branch' })
      vim.keymap.set('n', 'UO', '<cmd>G checkout -<cr>', { desc = 'Git: previous branch' })

      vim.keymap.set('n', 'Uz', '<cmd>G stash<cr>', { desc = 'Git: stash' })
      vim.keymap.set('n', 'UZ', '<cmd>G stash pop<cr>', { desc = 'Git: stash pop' })
    end,
  },
}
