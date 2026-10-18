local last_buffer_cwd = nil
local root_dir = vim.fs.normalize(vim.uv.cwd())

vim.api.nvim_create_autocmd('BufLeave', {
  callback = function()
    if vim.bo.buftype ~= 'terminal' then
      last_buffer_cwd = vim.uv.cwd()
    end
  end,
})

vim.api.nvim_create_autocmd({ 'BufEnter', 'TermEnter', 'TermLeave' }, {
  desc = 'cd to buffer cwd on enter',
  callback = function()
    if vim.bo.buftype == 'terminal' then
      if vim.b.terminal_job_pid == nil then
        return
      end
      local cwd = vim.fn.resolve('/proc/' .. vim.b.terminal_job_pid .. '/cwd')
      if vim.fn.isdirectory(cwd) == 0 then
        return
      end

      -- Skip dirs nested inside the directory Neovim was started in.
      for parent in vim.fs.parents(cwd) do
        if parent == root_dir then
          return
        end
      end

      vim.fn.chdir(cwd)
    elseif last_buffer_cwd then
      vim.fn.chdir(last_buffer_cwd)
    end
  end,
})
