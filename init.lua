--[[
--
o====================================================================
=====================================================================
=====================================================================
========                                    .-----.          ========
========         .----------------------.   | === |          ========
========         |.-""""""""""""""""""-.|   |-----|          ========
========         ||                    ||   | === |          ========
========         ||   KICKSTART.NVIM   ||   |-----|          ========
========         ||                    ||   | === |          ========
========         ||                    ||   |-----|          ========
========         ||:Tutor              ||   |:::::|          ========
========         |'-..................-'|   |____o|          ========
========        `"")----------------(""`   ___________      ========
========        /::::::::::|  |::::::::::\  \ no mouse \     ========
========       /:::========|  |==hjkl==:::\  \ required \    ========
========      '""""""""""""'  '""""""""""""'  '""""""""""'   ========
========                                                     ========
=====================================================================
=====================================================================
--
--]]
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require 'globals'
require 'core.options'
require 'core.keymaps'
require 'core.autocmds'
require 'core.terminal'
require 'custom.my.ctrl_s_shell'
require 'custom.my.tabs'
require 'custom.my.mistakes'

require('vim._core.ui2').enable {}

local oil_ex = require 'oil_filexplorer'
local ex = oil_ex:new()

local function vs_code()
  local vs_code_on = vim.g.vscode or false
  if vs_code_on then
    ex:kill()
    ex = oil_ex:new()
    vim.cmd 'se relativenumber'
    vim.g.vscode = false
  else
    ex:up()
    vim.cmd 'se norelativenumber'
    vim.g.vscode = true
  end
  ColourMyLines()
end

vim.api.nvim_create_user_command('VSCode', vs_code, {})
vim.keymap.set('n', '<leader>vs', vs_code, { desc = 'Toggle VSCode display with vs_code function.' })

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({ { import = 'custom/plugins' } }, { change_detection = { enabled = true, notify = false } })
