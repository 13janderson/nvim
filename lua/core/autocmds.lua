vim.api.nvim_create_autocmd({ 'BufEnter', 'FileType' }, {
  desc = 'Wrap markdown buffers only',
  group = vim.api.nvim_create_augroup('MarkdownWrapOn', { clear = true }),
  callback = function()
    vim.wo.wrap = vim.bo.filetype == 'markdown'
  end,
})

vim.api.nvim_create_autocmd('BufEnter', {
  desc = 'Override buffer format options',
  group = vim.api.nvim_create_augroup('override-formatoptions', { clear = true }),
  callback = function()
    vim.opt.formatoptions = 'jcrql'
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  callback = function()
    vim.keymap.set('n', '<CR>', '<CR>', { buffer = true, silent = true })
  end,
})

vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  callback = function()
    local qf = vim.fn.getqflist({ id = 0, items = true })
    for i, entry in ipairs(qf.items) do
      if entry.valid == 1 then
        -- Jump after the command finishes: `open_qflist`/`:copen` runs after
        -- this event and would otherwise leave the cursor in the qf window.
        local qfid = qf.id
        vim.schedule(function()
          -- Skip if the list was replaced or cleared in the meantime.
          if vim.fn.getqflist({ id = 0 }).id ~= qfid then
            return
          end
          if #vim.fn.getqflist() < i then
            return
          end
          vim.cmd('silent cc! ' .. i)
        end)
        return
      end
    end
  end,
})

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
