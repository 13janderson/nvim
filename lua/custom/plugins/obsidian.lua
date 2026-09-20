local function week_commencing(week_offset)
  week_offset = week_offset or 0
  local date = os.date '*t'
  local offset_to_monday = (date.wday == 1) and 6 or (date.wday - 2)
  local total_days = offset_to_monday - (week_offset * 7)
  return os.date('%a-%d-%b-%Y', os.time(date) - (total_days * 24 * 60 * 60))
end

return {
  'epwalsh/obsidian.nvim',
  version = '*',
  cond = vim.startswith(vim.fn.getcwd(), vim.fn.expand '~/vault'),
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {
    workspaces = {
      { name = 'Vault', path = '~/vault/' },
    },
    new_notes_location = 'current_dir',
    open_notes_in = 'current',
    completion = { nvim_cmp = true, min_chars = 1 },
    ui = { enable = false },
    follow_url_func = OpenLink,
    attachments = {
      img_folder = 'assets/imgs',
      img_name_func = function()
        return string.format('%s', os.time())
      end,
      img_text_func = function(client, path)
        local obsidian_path = require 'obsidian.path'
        local img_path = client:vault_relative_path(path) or path
        local relative_file_path = obsidian_path:new(vim.fn.expand '%:p:h'):relative_to(client:vault_root())
        local parts = 0
        for _ in string.gmatch(relative_file_path.filename, '[^/]+') do
          parts = parts + 1
        end
        return string.format('![%s](%s%s)', img_path.name, string.rep('../', parts), img_path.filename)
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
        wc = function()
          return week_commencing(0)
        end,
        lwc = function()
          return week_commencing(-1)
        end,
      },
    },
    picker = {
      name = 'telescope.nvim',
      note_mappings = { new = '<C-x>', insert_link = '<C-l>' },
      tag_mappings = { tag_note = '<C-]>', insert_tag = '<C-t>' },
    },
    daily_notes = {
      folder = 'daily',
      date_format = '%Y-%m-%d-%a',
      alias_format = '%B %-d, %Y',
      default_tags = { 'daily' },
      template = 'daily.md',
    },
  },
  config = function(_, opts)
    local obsidian = require 'obsidian'
    obsidian.setup(opts)

    local ok, err = pcall(function()
      vim.system({ 'obsidian' }, { detach = true }, function(obj)
        if obj.code ~= 0 then
          vim.schedule(function()
            vim.notify('Obsidian exited with code ' .. obj.code .. ': ' .. (obj.stderr or ''), vim.log.levels.WARN)
          end)
        end
      end)
    end)
    if not ok then
      vim.notify('Failed to start Obsidian: ' .. tostring(err), vim.log.levels.WARN)
    end

    vim.keymap.set('n', 'gf', obsidian.util.gf_passthrough)
    vim.keymap.set('n', '<M-x>', obsidian.util.toggle_checkbox)
    vim.keymap.set('n', '<M-p>', function()
      if vim.bo.filetype ~= 'markdown' then
        print 'This feature is only enabled for markdown files'
        return
      end
      vim.cmd(string.format('ObsidianPasteImg %s', opts.attachments.img_name_func()))
      vim.defer_fn(ReloadCurentBuffer, 250)
    end)
    vim.keymap.set('n', '<M-n>', function()
      vim.cmd 'ObsidianNewFromTemplate'
    end)

    local client = obsidian.get_client()
    local function has_obsidian_note(term)
      for _, note in ipairs(client:find_notes(term)) do
        if note ~= nil and note:fname() == term then
          return true
        end
      end
      return false
    end

    vim.keymap.set('n', '<M-w>', function()
      local weekly = 'weekly'
      local note_title = week_commencing(0) .. '.md'
      local weekly_note
      if not has_obsidian_note(note_title) then
        weekly_note = client:create_note { title = note_title, dir = weekly, template = weekly }
      end
      client:open_note(weekly_note or (weekly .. '/' .. note_title), {
        callback = function()
          vim.schedule(function()
            vim.api.nvim_win_set_cursor(0, { 9, 0 })
          end)
        end,
      })
    end)

    local function new_note_dir(dir)
      local ok, note_title = pcall(vim.fn.input, dir .. '/')
      if ok and not has_obsidian_note(note_title) then
        local note = client:create_note { title = note_title, id = note_title, dir = dir }
        client:open_note(note, { line = 8, col = 0 })
      end
    end

    vim.keymap.set('n', '<M-i>', function()
      new_note_dir '2_ideas'
    end)
    vim.keymap.set('n', '<M-s>', function()
      new_note_dir '1_source_material'
    end)
    vim.keymap.set('n', '<M-d>', function()
      vim.cmd 'ObsidianToday'
    end)
    vim.keymap.set('n', '<M-y>', function()
      vim.cmd 'ObsidianYesterday'
    end)
    vim.keymap.set('n', '<M-o>', function()
      vim.cmd 'ObsidianTomorrow'
    end)
    vim.keymap.set('n', '<leader>st', function()
      vim.cmd 'ObsidianTags'
    end)
  end,
}
