local opts_local_scope = {
  scope = 'local',
}

vim.fn.setreg('o', 'yiwoechoa ""hpa: $p_')
vim.fn.setreg('p', 'yiw}iechoa ""hpa: $p_')
vim.api.nvim_set_option_value('makeprg', 'bash %', opts_local_scope)
