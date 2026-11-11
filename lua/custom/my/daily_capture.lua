local M = {}

local committing = false

local function buffer_valid(buf)
  return buf and buf > 0 and vim.api.nvim_buf_is_valid(buf)
end

local function find_capture_buffer()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buffer_valid(buf) and vim.b[buf].daily_capture then
      return buf
    end
  end
end

local function close_buffer(buf)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    pcall(vim.api.nvim_win_close, win, true)
  end
  if buffer_valid(buf) then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

local function reload_if_open(path)
  local target = vim.fn.fnamemodify(path, ':p')
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buffer_valid(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= '' and vim.fn.fnamemodify(name, ':p') == target then
        vim.api.nvim_buf_call(buf, function()
          vim.cmd 'silent! checktime'
        end)
      end
    end
  end
end

local function append_to_daily(lines)
  local obsidian = require 'obsidian'
  local client = obsidian.get_client()
  local note = client:daily(0)
  local path = tostring(note.path)
  local file, open_err = io.open(path, 'a')
  if not file then
    error(open_err)
  end

  local ok, write_err = file:write(string.format('\n## %s\n\n%s\n', os.date '%H:%M', table.concat(lines, '\n')))
  local close_ok, close_err = file:close()
  if not ok then
    error(write_err)
  end
  if not close_ok then
    error(close_err)
  end

  reload_if_open(path)
  return path
end

local function commit(buf, closing)
  if not buffer_valid(buf) or committing or vim.b[buf].daily_capture_saved then
    return
  end

  committing = true

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  while #lines > 0 and lines[#lines]:match '^%s*$' do
    table.remove(lines)
  end
  while #lines > 0 and lines[1]:match '^%s*$' do
    table.remove(lines, 1)
  end

  if #lines == 0 then
    vim.b[buf].daily_capture_saved = true
    committing = false
    if not closing then
      close_buffer(buf)
    end
    return
  end

  local ok, result = pcall(append_to_daily, lines)
  committing = false
  if not ok then
    vim.notify(string.format('Daily capture failed: %s', result), vim.log.levels.ERROR)
    return
  end

  vim.b[buf].daily_capture_saved = true
  vim.notify(string.format('Captured to %s', vim.fn.fnamemodify(result, ':~')), vim.log.levels.INFO)
  if not closing then
    close_buffer(buf)
  end
end

function M.open()
  local existing = find_capture_buffer()
  if existing then
    local wins = vim.fn.win_findbuf(existing)
    if #wins > 0 then
      vim.api.nvim_set_current_win(wins[1])
    else
      vim.api.nvim_set_current_buf(existing)
    end
    vim.cmd 'startinsert'
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.b[buf].daily_capture = true
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].buflisted = false
  vim.bo[buf].filetype = 'markdown'

  local width = math.min(90, math.max(40, math.floor(vim.o.columns * 0.7)))
  local height = math.min(20, math.max(8, math.floor(vim.o.lines * 0.35)))
  local row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1)
  local col = math.max(0, math.floor((vim.o.columns - width) / 2))

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Capture to daily note ',
    title_pos = 'center',
  })

  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].spell = false

  vim.keymap.set('n', 'q', function()
    commit(buf, false)
  end, { buffer = buf, desc = 'Save capture and close' })

  vim.api.nvim_create_autocmd('BufUnload', {
    buffer = buf,
    once = true,
    callback = function()
      commit(buf, true)
    end,
  })

  vim.cmd 'startinsert'
end

vim.keymap.set('n', 'X', M.open, { desc = "Capture to today's daily note" })
vim.api.nvim_create_user_command('Capture', M.open, { desc = "Capture to today's daily note" })

return M
