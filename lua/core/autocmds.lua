vim.api.nvim_create_autocmd('BufEnter', {
  desc = 'Turn on linewrap for markdown files',
  pattern = { '*.md' },
  group = vim.api.nvim_create_augroup('MarkdownWrapOn', { clear = true }),
  callback = function()
    vim.opt.wrap = true
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
    for i, entry in ipairs(vim.fn.getqflist()) do
      if entry.valid ~= nil and entry.valid == 1 then
        vim.cmd(string.format('cc %d', i))
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
