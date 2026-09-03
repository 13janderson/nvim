return {
  {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = {
      { 'tpope/vim-dadbod',                     lazy = true },
      { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' } }, -- Remove lazy = true here
    },
    cmd = { 'DBUI', 'DBUIToggle', 'DBUIAddConnection', 'DBUIFindBuffer' },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "dbout",
        callback = function()
          vim.wo.foldenable = false
        end,
      })
      vim.g.dbs = {
        localhost = 'mysql://root:password@127.0.0.1:3306',
        localhost_2 = 'mysql://root:password@127.0.0.1:3307/defects',
        rgs_postgres = 'postgresql://postgres:Dev_9xK2mP7qL3@127.0.0.1:5433/versa-dev',
        wallet_postgres = 'postgresql://postgres:Dev_9xK2mP7qL3@127.0.0.1:5434/versa_wallet',
      }
    end,
  },
}
