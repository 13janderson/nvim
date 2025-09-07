return {
  'kiddos/gemini.nvim',
  opts = {},
  cond = not string.find(vim.fn.getcwd(), "CVS")
}
