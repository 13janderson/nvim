vim.o.winborder = 'rounded'
vim.g.have_nerd_font = true

-- We do not use Neovim's Python provider. Disable it so `has('python3')` does
-- not trigger slow host detection on the first Python buffer.
vim.g.loaded_python3_provider = 0
vim.g.loaded_python_provider = 0

vim.cmd [[
  let g:omni_sql_no_default_maps = 1
]]

vim.wo.relativenumber = true
vim.opt.number = true
vim.opt.mouse = 'a'
vim.opt.showmode = false
vim.opt.swapfile = false
vim.opt.breakindent = true
vim.opt.wrap = false
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.autoindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.splitright = true
vim.opt.updatetime = 250
vim.opt.list = false
vim.opt.inccommand = 'split'
vim.opt.cursorline = false
vim.opt.scrolloff = 10
vim.opt.confirm = false
vim.opt.termguicolors = true

-- Save the window layout, not every buffer and terminal we ever opened.
-- `buffers` makes persistence restore every listed/hidden buffer forever;
-- `terminal` resurrects dead terminal buffers.
vim.opt.sessionoptions = 'blank,curdir,folds,help,tabpages,winsize'

-- Treesitter supplies the fold expression; keep folds open until explicitly closed.
-- vim.opt.foldmethod = 'expr'
-- vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
-- vim.opt.foldlevel = 99
