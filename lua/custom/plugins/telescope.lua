return {
  {
    -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = 'make',

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
    },
    config = function()
      -- Telescope is a fuzzy finder that comes with a lot of different things that
      -- it can fuzzy find! It's more than just a "file finder", it can search
      -- many different aspects of Neovim, your workspace, LSP, and more!
      --
      -- The easiest way to use Telescope, is to start by doing something like:
      --  :Telescope help_tags
      --
      -- After running this command, a window will open up and you're able to
      -- type in the prompt window. You'll see a list of `help_tags` options and
      -- a corresponding preview of the help.
      --
      -- Two important keymaps to use while in Telescope are:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- Telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!

      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      local harpoon_telescope = require 'custom.my.telescope_harpoon'
      local telescope_actions = require 'telescope.actions'

      local function copy_selection(prompt_bufnr)
        local entry = require('telescope.actions.state').get_selected_entry()
        if not entry then
          return
        end
        telescope_actions.close(prompt_bufnr)
        vim.fn.setreg('+', entry.value)
        vim.notify(entry.value, nil, { title = 'Copied', icon = '󰅍' })
      end

      local function select_vertical_right(prompt_bufnr)
        local actions = require 'telescope.actions'
        local original_splitright = vim.o.splitright
        vim.o.splitright = true
        actions.select_vertical(prompt_bufnr)
        vim.o.splitright = original_splitright
      end

      local function select_horizontal_above(prompt_bufnr)
        local actions = require 'telescope.actions'
        local original_splitbelow = vim.o.splitbelow
        vim.o.splitbelow = false
        actions.select_horizontal(prompt_bufnr)
        vim.o.splitbelow = original_splitbelow
      end

      require('telescope').setup {
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`
        --
        defaults = {
          mappings = {
            i = {
              ['<C-c>'] = { telescope_actions.close, type = 'action', opts = { desc = 'Close' } },
              ['<C-j>'] = {
                telescope_actions.move_selection_next,
                type = 'action',
                opts = { desc = 'Next item' },
              },
              ['<C-k>'] = {
                telescope_actions.move_selection_previous,
                type = 'action',
                opts = { desc = 'Previous item' },
              },
              ['<C-v>'] = {
                select_vertical_right,
                type = 'action',
                opts = { desc = 'Open in vertical split' },
              },
              ['<C-s>'] = {
                select_horizontal_above,
                type = 'action',
                opts = { desc = 'Open in horizontal split (above)' },
              },
              ['<C-y>'] = { copy_selection, type = 'action', opts = { desc = 'Copy selection' } },
              ['<C-a>'] = {
                harpoon_telescope.add_only,
                type = 'action',
                opts = { desc = 'Add to Harpoon' },
              },
              ['<C-e>'] = {
                harpoon_telescope.add_and_open,
                type = 'action',
                opts = { desc = 'Add to Harpoon and open' },
              },
            },
            n = {
              ['<C-v>'] = {
                select_vertical_right,
                type = 'action',
                opts = { desc = 'Open in vertical split' },
              },
              ['<C-s>'] = {
                select_horizontal_above,
                type = 'action',
                opts = { desc = 'Open in horizontal split (above)' },
              },
              ['<C-h>'] = {
                harpoon_telescope.add_and_open,
                type = 'action',
                opts = { desc = 'Add to Harpoon and open' },
              }
            },
          },
          file_ignore_patterns = {
            '%.git/',        -- ignore .git folder
            'node_modules/', -- ignore node_modules
            '%.lock',        -- ignore lock files
            '%.jpg',
            '%.png',
            '%.jpeg', -- ignore image files
            '%.exe',
            '%.dll',  -- ignore binary files
            'build/',
            'dist/',  -- ignore build folders
          },
        },
        pickers = {
          find_files = {
            hidden = true,
            follow = true,
          },
          live_grep = {
            hidden = true,
            -- follow = true,
          },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }


      -- Enable Telescope extensions if they are installed
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')
      pcall(require('telescope').load_extension, 'git_worktree')

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'

      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      -- vim.keymap.set('n', '<leader>sG', live_multigrep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>s/', builtin.current_buffer_fuzzy_find, { desc = '[S]earch [/]' })
      vim.keymap.set('n', '<leader>sd', function()
        builtin.diagnostics({ bufnr = 0 })
      end, { desc = '[S]earch Markdown [D]ocument headings or [D]iagnostics' })
      vim.keymap.set('n', '<leader>sD', function()
        builtin.diagnostics({
          bufnr = nil,
        })
      end, { desc = '[S]earch all buffer [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>sm', builtin.marks, { desc = '[S]earch [M]arks' })
      vim.keymap.set('n', '<leader>su', builtin.buffers, { desc = '[S]earch B[u]ffers' })
      vim.keymap.set('n', '<leader>sb', builtin.git_branches, { desc = '[S]earch [B]ranches' })
      vim.keymap.set('n', '<leader>sz', builtin.git_stash, { desc = '[S]earch Stas[h]' })
      vim.keymap.set('n', '<leader>s:', builtin.command_history, { desc = '[S]earch [C]ommands' })

      vim.api.nvim_create_user_command('TelescopeColors', function()
        builtin.colorscheme {
          enable_preview = true,
        }
      end, {})
    end,
  },
  {
    'rafi/telescope-thesaurus.nvim',
    dependencies = {
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      vim.g.thesaurus = {
        provider = 'dictionaryapi',                       -- default: 'dictionaryapi'
        picker = 'telescope',                             -- default: 'auto', snacks if installed, else telescope
        -- Fine to commit this tbh, it's a free API.
        api_key = '91a26400-a3ef-4013-824b-068b62c22e7b', -- dictionaryapi.com key, default: $DICTIONARY_API_KEY
        loading = true,                                   -- show a "Loading..." popup during a lookup
      }
      vim.keymap.set('n', 'zl', function()
        require('thesaurus').lookup {
          layout_strategy = 'cursor',
          layout_config = {
            width = 0.6,
            height = 0.5,
            prompt_position = 'top',
          },
        }
      end, { desc = 'Thesaurus lookup' })
    end,
  },
}
