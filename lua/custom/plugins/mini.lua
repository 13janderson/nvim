return {
  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      local spec_treesitter = require('mini.ai').gen_spec.treesitter
      require('mini.ai').setup {
        n_lines = 500,
        custom_textobjects = {
          F = spec_treesitter { a = '@function.outer', i = '@function.inner' },
          o = spec_treesitter {
            a = { '@conditional.outer', '@loop.outer' },
            i = { '@conditional.inner', '@loop.inner' },
          },
        },
      }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] ['']
      require('mini.surround').setup()

      -- Simple and easy statusline.
      local statusline = require 'mini.statusline'

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end

      local function section_git_worktree()
        local head = vim.b.gitsigns_head or vim.b.fugitive_head or ''
        local worktree = ''
        local ok, gw = pcall(require, 'git-worktree')
        if ok then
          local path = gw.get_current_worktree_path and gw.get_current_worktree_path() or ''
          if path and path ~= '' then
            local tail = vim.fn.fnamemodify(path, ':t')
            local cwd_tail = vim.fn.fnamemodify(vim.loop.cwd(), ':t')
            if tail ~= '' and tail ~= cwd_tail then
              worktree = '[' .. tail .. ']'
            end
          end
        end
        if head == '' then
          return ''
        end
        return worktree .. ' ' .. head
      end

      local function section_terminal()
        if vim.bo.buftype ~= 'terminal' then
          return ''
        end
        local name = vim.api.nvim_buf_get_name(0)
        if name:match('opencode') then
          return '󰭹 opencode'
        elseif name:match('hunk') then
          return '󰊢 hunk'
        elseif name:match('lazydocker') then
          return '󰡨 docker'
        else
          return '󰆍 shell'
        end
      end

      local function section_harpoon()
        local ok, harpoon = pcall(require, 'harpoon')
        if not ok then
          return ''
        end
        local list = harpoon:list()
        local items = list and list.items or {}
        local path = vim.api.nvim_buf_get_name(0)
        for i, item in ipairs(items) do
          if item.value == path then
            return '󰛢 ' .. i
          end
        end
        return ''
      end

      local function section_lsp()
        local clients = vim.lsp.get_clients { bufnr = 0 }
        if #clients == 0 then
          return ''
        end
        local names = {}
        for _, c in ipairs(clients) do
          table.insert(names, c.name)
        end
        return ' ' .. table.concat(names, ',')
      end

      local function section_dap()
        local ok, dap = pcall(require, 'dap')
        if not ok or not dap.session() then
          return ''
        end
        return ' DEBUG'
      end

      local function section_macro()
        local recording = vim.fn.reg_recording()
        if recording == '' then
          return ''
        end
        return ' @' .. recording
      end

      local function section_vault()
        if vim.startswith(vim.fn.getcwd(), vim.fn.expand '~/vault') then
          return '󰠮 vault'
        end
        return ''
      end

      local function section_diagnostics()
        local counts = { 0, 0, 0, 0 }
        for _, d in ipairs(vim.diagnostic.get(0)) do
          counts[d.severity] = counts[d.severity] + 1
        end
        local result = {}
        if counts[vim.diagnostic.severity.ERROR] > 0 then
          table.insert(result, '󰅚 ' .. counts[vim.diagnostic.severity.ERROR])
        end
        if counts[vim.diagnostic.severity.WARN] > 0 then
          table.insert(result, '󰀪 ' .. counts[vim.diagnostic.severity.WARN])
        end
        return table.concat(result, ' ')
      end

      statusline.setup {
        content = {
          active = function()
            local mode, mode_hl = statusline.section_mode { trunc_width = 120 }
            local git = section_git_worktree()
            local diagnostics = section_diagnostics()
            local lsp = section_lsp()
            local filename = statusline.section_filename { trunc_width = 140 }
            local fileinfo = statusline.section_fileinfo { trunc_width = 120 }
            local location = statusline.section_location {}
            local terminal = section_terminal()
            local harpoon = section_harpoon()
            local macro = section_macro()
            local dap = section_dap()
            local vault = section_vault()

            return statusline.combine_groups {
              { hl = mode_hl, strings = { mode, macro, dap } },
              { hl = 'MiniStatuslineDevinfo', strings = { git, vault, terminal } },
              '%<',
              { hl = 'MiniStatuslineFilename', strings = { filename } },
              '%=',
              { hl = 'MiniStatuslineDevinfo', strings = { diagnostics, lsp, harpoon } },
              { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
              { hl = mode_hl, strings = { location } },
            }
          end,
        },
      }

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
    end,
  },
}
