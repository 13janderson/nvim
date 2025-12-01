local function week_commencing(week_offset)
  week_offset = week_offset or 0 -- 0 = this week, -1 = last week, +1 = next week, etc.

  local t = os.date("*t")
  local wday = t.wday -- 1 = Sunday, 2 = Monday, ..., 7 = Saturday

  local offset_to_monday = (wday == 1) and 6 or (wday - 2)
  local total_days = offset_to_monday - (week_offset * 7)
  local week_start = os.time(t) - (total_days * 24 * 60 * 60)
  return os.date("%a-%d-%b-%Y", week_start)
end

return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown"onedark"'
    ---@type render.md.UserConfig
    opts = {
      only_render_image_at_cursor = false,
    },
  },
  -- {
  --   '3rd/image.nvim',
  --   config = function()
  --     require("image").setup({
  --       backend = "kitty",        -- or "ueberzug" or "sixel"
  --       processor = "magick_cli", -- or "magick_rock"
  --       integrations = {
  --         markdown = {
  --           enabled = true,
  --           clear_in_insert_mode = false,
  --           download_remote_images = true,
  --           only_render_image_at_cursor = false,
  --           only_render_image_at_cursor_mode = "popup", -- or "inline"
  --           floating_windows = false,                   -- if true, images will be rendered in floating markdown windows
  --           filetypes = { "markdown", "vimwiki" },      -- markdown extensions (ie. quarto) can go here
  --         },
  --         neorg = {
  --           enabled = true,
  --           filetypes = { "norg" },
  --         },
  --         typst = {
  --           enabled = true,
  --           filetypes = { "typst" },
  --         },
  --         html = {
  --           enabled = false,
  --         },
  --         css = {
  --           enabled = false,
  --         },
  --       },
  --       max_width = nil,
  --       max_height = nil,
  --       max_width_window_percentage = nil,
  --       max_height_window_percentage = 50,
  --       scale_factor = 1.0,
  --       window_overlap_clear_enabled = false,                                               -- toggles images when windows are overlapped
  --       window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "snacks_notif", "scrollview", "scrollview_sign" },
  --       editor_only_render_when_focused = false,                                            -- auto show/hide images when the editor gains/looses focus
  --       tmux_show_only_in_active_window = false,                                            -- auto show/hide images in the correct Tmux window (needs visual-activity off)
  --       hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" }, -- render image files as images when opened
  --     })
  --   end
  -- },
  {
    'toppair/peek.nvim',
    build = 'deno task --quiet build:fast',
    config = function()
      require('peek').setup {
        app = 'browser',
        auto_load = true,
      }
      vim.api.nvim_create_user_command('PeekOpen', require('peek').open, {})
      vim.api.nvim_create_user_command('PeekClose', require('peek').close, {})

      -- Close vim all together, this way we can have a persistent window for previewing markdown files
      vim.api.nvim_create_autocmd('VimLeave', {
        pattern = { '*.md' },
        group = vim.api.nvim_create_augroup('PeekCloseOnLeave', { clear = true }),
        callback = function(_)
          local peek = require 'peek'
          if peek.is_open() then
            peek.close()
          end
        end,
      })
      vim.api.nvim_create_user_command('Preview', function(_)
        local peek = require 'peek'
        if not peek.is_open() then
          peek.close()
          local filetype = vim.bo.filetype
          if filetype == 'markdown' then
            peek.open()
            print 'Markdown preview opened'
          else
            print 'Filetype must be markdown'
          end
          Clear(500)
        end
      end, {})
    end,
  },
  {
    'epwalsh/obsidian.nvim',
    version = '*', -- recommended, use latest release instead of latest commit
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    cond = vim.startswith(vim.fn.getcwd(), vim.fn.expand '~/vault'),
    dependencies = {
      -- Required.
      'nvim-lua/plenary.nvim',
    },
    opts = {
      workspaces = {
        {
          name = 'Vault',
          path = '~/vault/',
        },
      },
      new_notes_location = 'current_dir',
      open_notes_in = 'current',
      completion = {
        -- Set to false to disable completion.
        nvim_cmp = true,
        -- Trigger completion at 1 chars.
        min_chars = 1,
      },
      ui = {
        enable = false,
      },
      follow_url_func = OpenLink,
      -- Specify how to handle attachments.
      attachments = {
        -- The default folder to place images in via `:ObsidianPasteImg`.
        -- If this is a relative path it will be interpreted as relative to the vault root.
        -- You can always override this per image by passing a full path to the command instead of just a filename.
        img_folder = 'assets/imgs', -- This is the default

        -- Optional, customize the default name or prefix when pasting images via `:ObsidianPasteImg`.
        ---@return string
        img_name_func = function()
          -- Prefix image names with timestamp.
          return string.format('%s', os.time())
        end,

        -- A function that determines the text to insert in the note when pasting an image.
        -- It takes two arguments, the `obsidian.Client` and an `obsidian.Path` to the image file.
        -- This is the default implementation.
        ---@param client obsidian.Client
        ---@param path obsidian.Path the absolute path to the image file
        ---@return string
        img_text_func = function(client, path)
          local obsidian_path = require 'obsidian.path'
          local img_path = client:vault_relative_path(path) or path
          local relative_file_path = obsidian_path:new(vim.fn.expand '%:p:h'):relative_to(client:vault_root())

          local function count_path_parts(pth, sep)
            sep = sep or '/' -- default to Unix-style
            local count = 0
            for _ in string.gmatch(pth, '[^' .. sep .. ']+') do
              count = count + 1
            end
            return count
          end

          local parts = count_path_parts(relative_file_path.filename)

          local out = ''
          for _ = 1, parts, 1 do
            out = out .. '../'
          end

          out = out .. img_path.filename
          return string.format('![%s](%s)', img_path.name, out)
        end,
      },

      templates = {
        folder = 'templates',
        date_format = '%Y-%m-%d-%a',
        time_format = '%H:%M',
        substitutions = {
          yesterday = function()
            return os.date('%Y-%m-%d-%a', os.time() - 86400)
          end,
          tomorrow = function()
            return os.date('%Y-%m-%d-%a', os.time() + 86400)
          end,
          wc = function() return week_commencing(0) end,
          lwc = function() return week_commencing(-1) end,
        },
      },

      -- TODO customise these keybindings to my liking.
      picker = {
        -- Set your preferred picker. Can be one of 'telescope.nvim', 'fzf-lua', or 'mini.pick'.
        name = 'telescope.nvim',
        -- Optional, configure key mappings for the picker. These are the defaults.
        -- Not all pickers support all mappings.
        note_mappings = {
          -- Create a new note from your query.
          new = '<C-x>',
          -- Insert a link to the selected note.
          insert_link = '<C-l>',
        },
        tag_mappings = {
          -- Add tag(s) to current note.
          -- Somehow ] feels like tagging?
          tag_note = '<C-]>',
          -- Insert a tag at the current location.
          insert_tag = '<C-t>',
        },
      },

      daily_notes = {
        -- Optional, if you keep daily notes in a separate directory.
        folder = 'daily',
        -- Optional, if you want to change the date format for the ID of daily notes.
        date_format = '%Y-%m-%d-%a',
        -- Optional, if you want to change the date format of the default alias of daily notes.
        alias_format = '%B %-d, %Y',
        -- Optional, default tags to add to each new daily note created.
        default_tags = { 'daily' },
        -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
        template = 'daily.md',
      },

      -- -- Customize the frontmatter data.
      -- ---@param note obsidian.Note
      -- ---@return table
      -- note_frontmatter_func = function(note)
      --   -- Add the title of the note as an alias.
      --   local out = { id = note.id, aliases = note.aliases, tags = note.tags }
      --
      --   -- `note.metadata` contains any manually added fields in the frontmatter.
      --   -- So here we just make sure those fields are kept in the frontmatter.
      --   if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
      --     for k, v in pairs(note.metadata) do
      --       out[k] = v
      --     end
      --   end
      --
      --   return out
      -- end,
    },
    config = function(_, opts)
      -- Set a custom colourscheme when this plugin is loaded, gives the illusion
      -- that we are in another application specifically for editing text.
      -- ColourMyPencils("tokionight")

      local obsidian = require 'obsidian'
      obsidian.setup(opts)

      -- Keymappings here
      vim.keymap.set('n', 'gf', obsidian.util.gf_passthrough, nil)
      vim.keymap.set('n', '<M-x>', obsidian.util.toggle_checkbox, nil)
      vim.keymap.set('n', '<M-i>', function()
        local filetype = vim.bo.filetype
        if filetype == 'markdown' then
          vim.cmd(string.format('ObsidianPasteImg %s', opts.attachments.img_name_func()))
          vim.defer_fn(function()
            ReloadCurentBuffer()
          end, 250)
        else
          print 'This feature is only enabled for markdown files'
        end
      end, nil)

      local jumpToString = function(to)
        -- Jump to first section, i.e. Admin and go into insert mode below it
        local termcodes = vim.api.nvim_replace_termcodes(string.format('/%s<CR>', to), true, false, true)
        vim.api.nvim_feedkeys(termcodes, 'n', false)
        Clear(250)
      end

      local learnJumpTo = function()
        jumpToString 'Overview'
      end

      -- Create new note from a template
      vim.keymap.set('n', '<M-n>', function()
        vim.cmd 'ObsidianNewFromTemplate'
      end)

      vim.keymap.set('n', '<M-w>', function()
        -- This is the dogs bollocks
        local client = obsidian.get_client()
        local note_title = week_commencing(0) .. ".md"
        local weekly_note = client:create_note({
          title = note_title,
          dir = "weekly",
          template = "weekly"
        })
        client:open_note(weekly_note, {
          line = 6,
          col = 0
        })
      end)

      -- Create new daily note
      vim.keymap.set('n', '<M-d>', function()
        vim.cmd 'ObsidianToday'
      end)

      -- Navigate to yesterday's daily note
      vim.keymap.set('n', '<M-y>', function()
        vim.cmd 'ObsidianYesterday'
      end)

      -- Create daily note for tomorrow
      vim.keymap.set('n', '<M-o>', function()
        vim.cmd 'ObsidianTomorrow'
      end)

      -- Telescope like searching [S]earch [T]ags
      -- tag_note = "<C-]>",
      -- insert_tag = "<C-t>",
      -- Is there a way to get this to multi-select properly?
      vim.keymap.set('n', '<leader>st', function()
        vim.cmd 'ObsidianTags'
      end, nil)

      -- Auto commands specifically for obsidian related buffers
      vim.api.nvim_create_autocmd('BufNewFile', {
        desc = 'Auto Commands for new Markdow files made in vault.',
        pattern = { vim.fn.expand '~/vault' .. '*.md' },
        group = vim.api.nvim_create_augroup('NewVaultFile', { clear = true }),
        callback = function(e)
          -- TODO, what do we want to do with this?
        end,
      })
    end,
  },
}
