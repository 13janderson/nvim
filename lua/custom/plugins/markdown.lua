return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown"onedark"'
    ---@type render.md.UserConfig
    opts = {
      only_render_image_at_cursor = true
    }

  },
  {
    "toppair/peek.nvim",
    build = "deno task --quiet build:fast",
    config = function()
      require("peek").setup({
        app = 'browser',
        auto_load = true,
      })
      vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
      vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})

      -- Close vim all together, this way we can have a persistent window for previewing markdown files
      vim.api.nvim_create_autocmd("VimLeave", {
        pattern = { "*.md" },
        group = vim.api.nvim_create_augroup('PeekCloseOnLeave', { clear = true }),
        callback = function(_)
          local peek = require("peek")
          if peek.is_open() then
            peek.close()
          end
        end
      })
      vim.api.nvim_create_user_command("Preview", function(_)
        local peek = require("peek")
        if not peek.is_open() then
          peek.close()
          local filetype = vim.bo.filetype
          if filetype == "markdown" then
            peek.open()
            print("Markdown preview opened")
          else
            print("Filetype must be markdown")
          end
          Clear(500)
        end
      end, {})
    end
  },
  {
    "epwalsh/obsidian.nvim",
    -- requires xclip for copying images from clipboard in linux
    version = "*", -- recommended, use latest release instead of latest commit
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    cond = vim.startswith(vim.fn.getcwd(), vim.fn.expand "~/vault"),
    dependencies = {
      -- Required.
      "nvim-lua/plenary.nvim",
    },
    opts = {
      workspaces = {
        {
          name = "Vault",
          path = "~/vault/",
        },
      },
      new_notes_location = "current_dir",
      open_notes_in = "current",
      completion = {
        -- Set to false to disable completion.
        nvim_cmp = true,
        -- Trigger completion at 1 chars.
        min_chars = 1,
      },
      ui = {
        enable = false,
      },
      -- Specify how to handle attachments.
      attachments = {
        -- The default folder to place images in via `:ObsidianPasteImg`.
        -- If this is a relative path it will be interpreted as relative to the vault root.
        -- You can always override this per image by passing a full path to the command instead of just a filename.
        img_folder = "assets/imgs", -- This is the default

        -- Optional, customize the default name or prefix when pasting images via `:ObsidianPasteImg`.
        ---@return string
        img_name_func = function()
          -- Prefix image names with timestamp.
          return string.format("%s", os.time())
        end,

        -- A function that determines the text to insert in the note when pasting an image.
        -- It takes two arguments, the `obsidian.Client` and an `obsidian.Path` to the image file.
        -- This is the default implementation.
        ---@param client obsidian.Client
        ---@param path obsidian.Path the absolute path to the image file
        ---@return string
        img_text_func = function(client, path)
          path = client:vault_relative_path(path) or path
          return string.format("![%s](%s)", path.name, path)
        end,
      },

      templates = {
        folder = "templates",
        date_format = "%Y-%m-%d-%a",
        time_format = "%H:%M",
        substitutions = {
          yesterday = function()
            return os.date("%Y-%m-%d-%a", os.time() - 86400)
          end,
          tomorrow = function()
            return os.date("%Y-%m-%d-%a", os.time() + 86400)
          end
        }
      },

      daily_notes = {
        -- Optional, if you keep daily notes in a separate directory.
        folder = "daily",
        -- Optional, if you want to change the date format for the ID of daily notes.
        date_format = "%Y-%m-%d-%a",
        -- Optional, if you want to change the date format of the default alias of daily notes.
        alias_format = "%B %-d, %Y",
        -- Optional, default tags to add to each new daily note created.
        default_tags = { "daily" },
        -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
        template = "daily.md"
      },
    },
    config = function(_, opts)
      -- Set a custom colourscheme when this plugin is loaded, gives the illusion
      -- that we are in another application specifically for editing text.
      -- ColourMyPencils("tokionight")

      local obsidian = require("obsidian")
      obsidian.setup(opts)

      -- Keymappings here
      vim.keymap.set("n", "gf", obsidian.util.gf_passthrough, nil)
      vim.keymap.set("n", "<M-x>", obsidian.util.toggle_checkbox, nil)
      vim.keymap.set("n", "<M-i>", function()
        local filetype = vim.bo.filetype
        if filetype == "markdown" then
          vim.cmd(string.format("ObsidianPasteImg %s", opts.attachments.img_name_func()))
          local vault = vim.fn.expand "~/vault/"
          -- Hack add the full path to the vault by prepending the expansion of ~/vault
          -- since thats where our images live.
          local keys = string.format("_ci(%s<C-C>p", vault)
          local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
          vim.api.nvim_feedkeys(termcodes, "n", false)

          -- Horrible hack to get this weird formatting to disappear.
          -- This seems to happen regardless of terminal emulator but this hack this infact work
          -- and I hate it.
          vim.defer_fn(function()
            ReloadCurentBuffer()
          end, 250)
        else
          print("This feature is only enabled for markdown files")
        end
      end, nil)
      vim.keymap.set("n", "<cr>", obsidian.util.smart_action, { buffer = true, expr = true })

      local jumpToString = function(to)
        -- Jump to first section, i.e. Admin and go into insert mode below it
        local termcodes = vim.api.nvim_replace_termcodes(string.format("/%s<CR>", to), true, false, true)
        vim.api.nvim_feedkeys(termcodes, "n", false)
        Clear(250)
      end

      local learnJumpTo = function()
        jumpToString("Overview")
      end

      -- Create new note from a template
      vim.keymap.set("n", "<M-n>", function()
        vim.cmd("ObsidianNewFromTemplate")
      end)

      -- Create new daily note
      vim.keymap.set("n", "<M-d>", function()
        vim.cmd("ObsidianToday")
      end)

      -- Navigate to yesterday's daily note
      vim.keymap.set("n", "<M-y>", function()
        vim.cmd("ObsidianYesterday")
      end)

      -- Create daily note for tomorrow
      vim.keymap.set("n", "<M-o>", function()
        vim.cmd("ObsidianTomorrow")
      end)


      -- Auto commands specifically for obsidian related buffers
      vim.api.nvim_create_autocmd('BufNewFile', {
        desc = 'Auto Commands for new Markdow files made in vault.',
        pattern = { vim.fn.expand "~/vault" .. "*.md" },
        group = vim.api.nvim_create_augroup('NewVaultFile', { clear = true }),
        callback = function(e)
          -- TODO, what do we want to do with this?
        end,
      })
    end,
  }
}
