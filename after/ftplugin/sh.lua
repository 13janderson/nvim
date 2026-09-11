vim.opt_local.makeprg = 'bash %'

vim.fn.setreg('o', 'yiwoechoa ""hpa: $p_')
vim.fn.setreg('p', 'yiw}koechoa ""hpa: $p_')
vim.api.nvim_set_option_value('makeprg', 'bash %', opts_local_scope)

vim.b.undo_ftplugin = 'setlocal makeprg<'
