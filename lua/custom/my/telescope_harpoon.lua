local M = {}

local function entry_file(entry)
  if not entry then
    return nil
  end

  local path = entry.path or entry.filename
  if type(path) ~= 'string' or path == '' then
    return nil
  end

  path = vim.fn.fnamemodify(path, ':p')
  if vim.fn.filereadable(path) ~= 1 then
    return nil
  end

  return path
end

--- Add a Telescope entry to the current Harpoon list.
--- Returns false for entries that don't resolve to a real file (branches,
--- commits, help tags, command history, ...).
function M.add(entry)
  local path = entry_file(entry)
  if not path then
    return false
  end

  local ok, harpoon = pcall(require, 'harpoon')
  if not ok then
    vim.notify('Harpoon is not available', vim.log.levels.WARN)
    return false
  end

  local added, err = pcall(function()
    harpoon:list():add {
      value = path,
      context = {
        row = entry.lnum or 1,
        col = entry.col or 1,
      },
    }
  end)

  if not added then
    vim.notify('Harpoon add failed: ' .. tostring(err), vim.log.levels.WARN)
    return false
  end

  return true
end

--- Add the selected entry, then close the picker.
function M.add_only(prompt_bufnr)
  local entry = require('telescope.actions.state').get_selected_entry()
  require('telescope.actions').close(prompt_bufnr)
  M.add(entry)
end

--- Add the selected entry, then perform the picker's normal open action.
function M.add_and_open(prompt_bufnr)
  local entry = require('telescope.actions.state').get_selected_entry()
  M.add(entry)
  require('telescope.actions').select_default(prompt_bufnr)
end

return M
