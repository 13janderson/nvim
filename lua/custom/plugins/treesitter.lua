return {
  {
    'nvim-treesitter/nvim-treesitter-context',
    config = function()
      vim.keymap.set('n', 'gt', function()
        require('treesitter-context').go_to_context(vim.v.count1)
      end, { silent = true })
      require('treesitter-context').setup {
        opts = {
          enable = true,
        },
      }
    end,
  },
  {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    main = 'nvim-treesitter', -- Sets main module to use for opts
    auto_install = true,
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    opts = {
      -- ensure_installed = {
      --   'bash',
      --   'c',
      --   'diff',
      --   'html',
      --   'lua',
      --   'luadoc',
      --   'markdown',
      --   'markdown_inline',
      --   'query',
      --   'terraform',
      --   'vim',
      --   'vimdoc',
      --   'go',
      --   'typescript',
      --   'javascript',
      --   'c_sharp',
      --   'powershell',
      --   'yaml',
      --   'python',
      --   'prisma',
      -- },
    },
    init = function()
      vim.api.nvim_create_autocmd('FileType', {
        callback = function()
          -- Enable treesitter highlighting and disable regex syntax
          pcall(vim.treesitter.start)
          -- Enable treesitter-based indentation
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })

      local ensureInstalled = {
        'bash',
        'c',
        'diff',
        'html',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'terraform',
        'vim',
        'vimdoc',
        'go',
        'typescript',
        'javascript',
        'c_sharp',
        'powershell',
        'yaml',
        'python',
        'prisma',
        -- ... your parsers
      }
      local alreadyInstalled = require('nvim-treesitter.config').get_installed()
      local parsersToInstall = vim
        .iter(ensureInstalled)
        :filter(function(parser)
          return not vim.tbl_contains(alreadyInstalled, parser)
        end)
        :totable()
      require('nvim-treesitter').install(parsersToInstall)
    end,
    -- Autoinstall languages that are not installed
    -- highlight = {
    --   enable = true,
    --   -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
    --   --  If you are experiencing weird indenting issues, add the language to
    --   --  the list of additional_vim_regex_highlighting and disabled languages for indent.
    --   additional_vim_regex_highlighting = { 'ruby', 'markdown' },
    -- },
    -- indent = { enable = true, disable = { 'ruby', 'sql' } },
  },
}
