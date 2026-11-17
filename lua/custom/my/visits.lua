local M = {}

local function is_useful_visit(item)
  if item.path:match '/scratch%.md$' then
    return false
  end
  if vim.startswith(item.path, '/tmp/') then
    return false
  end
  return true
end

local function project_root()
  local name = vim.api.nvim_buf_get_name(0)
  return vim.fs.normalize(vim.fs.root(name ~= '' and name or vim.fn.getcwd(), { '.git' }) or vim.fn.getcwd())
end

local function make_filter(root)
  local prefix = root:sub(-1) == '/' and root or (root .. '/')

  return function(item)
    if not is_useful_visit(item) then
      return false
    end

    local path = vim.fs.normalize(item.path)
    return path == root or vim.startswith(path, prefix)
  end
end

local function pick_project()
  local ok, visits = pcall(require, 'mini.visits')
  if not ok then
    vim.notify('mini.visits is not available', vim.log.levels.WARN)
    return
  end

  local items = visits.list_paths('', { filter = make_filter(project_root()) })
  if #items == 0 then
    vim.notify('No visits recorded for this project yet', vim.log.levels.INFO)
    return
  end

  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local make_entry = require 'telescope.make_entry'
  local conf = require('telescope.config').values

  -- Use Telescope's file entry maker so entries get devicons, a proper
  -- `path`, and the file previewer.
  pickers
    .new({}, {
      prompt_title = 'Visits (project frecency)',
      finder = finders.new_table {
        results = items,
        entry_maker = make_entry.gen_from_file {},
      },
      previewer = conf.file_previewer {},
      sorter = conf.generic_sorter {},
    })
    :find()
end

M.pick_project = pick_project

function M.setup()
  vim.keymap.set('n', '<leader>sv', M.pick_project, { desc = 'Visits: [S]earch project by frecency' })
end

return M
