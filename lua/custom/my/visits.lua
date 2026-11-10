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

local function make_entry(item)
  local display = vim.fn.fnamemodify(item.path, ':~:.')
  local labels = item.labels and vim.tbl_keys(item.labels) or {}
  if #labels > 0 then
    display = display .. ' [' .. table.concat(labels, ', ') .. ']'
  end

  return {
    value = item.path,
    display = display,
    ordinal = display,
    filename = item.path,
  }
end

local function pick(cwd, title)
  local ok, visits = pcall(require, 'mini.visits')
  if not ok then
    vim.notify('mini.visits is not available', vim.log.levels.WARN)
    return
  end

  local items = visits.list_paths(cwd, { filter = is_useful_visit })
  if #items == 0 then
    vim.notify('No visits recorded yet', vim.log.levels.INFO)
    return
  end

  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values

  pickers
    .new({}, {
      prompt_title = title,
      finder = finders.new_table {
        results = items,
        entry_maker = make_entry,
      },
      previewer = conf.file_previewer {},
      sorter = conf.generic_sorter {},
    })
    :find()
end

function M.setup()
  vim.keymap.set('n', '<leader>sv', function()
    pick(nil, 'Visits (project frecency)')
  end, { desc = 'Visits: [S]earch project by frecency' })

  vim.keymap.set('n', '<leader>sV', function()
    pick('', 'Visits (all frecency)')
  end, { desc = 'Visits: [S]earch all by frecency' })
end

return M
