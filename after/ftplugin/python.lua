local opts_local_scope = {
  scope = 'local',
}

vim.fn.setreg("o", 'yiwoprint()if""hpa: {}hp_')
vim.fn.setreg("p", 'yiw}iprint()if""hpa: {}hp_')
vim.fn.setreg("l", 'yiw}ilogger.info()if""hpa: {}hp_')

-- Set error format as per https://github.com/idbrii/vim-david/blob/main/compiler/python.vim
local errorformat = '%A%\\s%#File \"%f\"\\, line %l\\, in%.%#'

-- Include failed toplevel doctest example.
errorformat = errorformat .. ',%+CFailed example:%.%#'

-- Ignore big star lines from doctests.
errorformat = errorformat .. ',%-G*%\\{70%\\}'

-- Ignore most of doctest summary.
errorformat = errorformat .. ',%-G%*\\d items had failures:'

-- SyntaxErrors
errorformat = errorformat .. ',%E  File \"%f\"\\, line %l'
errorformat = errorformat .. ',%-C%p^'
errorformat = errorformat .. ',%+C  %m'
errorformat = errorformat .. ',%Z  %m'

vim.api.nvim_set_option_value("errorformat", errorformat, opts_local_scope)
vim.api.nvim_set_option_value('makeprg', 'python -t -u', opts_local_scope)
