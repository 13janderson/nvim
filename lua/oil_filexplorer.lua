-- Poor mans use of oil.nvim as a filetree
---@class OilFileEx
local OilFileEx = {}

---@return string
local function get_current_parent_dir()
  return vim.fn.expand('%:p:h')
end

local function is_oil_buffer(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    return string.find(bufname, "^oil")
  end
end

function OilFileEx:open_oil_dir()
  local dir = get_current_parent_dir()
  require "oil".open(dir)
  self.curdir = dir
end

-- Opens the filetree to the left of the current window
-- and sets up an autocmd for
function OilFileEx:up()
  self.code_winnr = vim.api.nvim_get_current_win()
  self.code_bufnr = vim.api.nvim_get_current_buf()

  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("OilFileTreeCodeWindow", { clear = true }),
    callback = function(_)
      if not vim.api.nvim_win_is_valid(self.code_winnr) or self.killed then
        return
      end

      local bufnr = vim.api.nvim_win_get_buf(self.code_winnr)
      if bufnr ~= self.code_bufnr and not is_oil_buffer(bufnr) then
        print "reloading from code window"
        self.code_bufnr = bufnr
        self:reload_if_dir_changed()
      end
    end
  })
  self:load()
end

function OilFileEx:oil_should_reload()
  return get_current_parent_dir() ~= self.curdir
end

function OilFileEx:load()
  vim.cmd("40vs")
  self:open_oil_dir()
  self.oil_bufnr = vim.api.nvim_get_current_buf()
  self.oil_winnr = vim.api.nvim_get_current_win()

  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("OilFileTreeOilWindow", { clear = true }),
    callback = function(_)
      if not vim.api.nvim_win_is_valid(self.oil_winnr) then
        return
      end

      local bufnr = vim.api.nvim_win_get_buf(self.oil_winnr)
      if bufnr ~= self.oil_bufnr then
        -- reload oil if anything but an oil buffer is
        -- loaded in the designated oil window
        if not is_oil_buffer(bufnr) then
          print "reloading"
          self:reload()
          -- put whatever was loaded into the code window
          vim.api.nvim_win_set_buf(self.code_winnr, bufnr)
        else
          print "not reloading"
        end
      end
    end
  })

  -- set focus back on self.winnr
  vim.api.nvim_set_current_win(self.code_winnr)
end

function OilFileEx:reload()
  vim.schedule(function()
    self:down()
    self:load()
  end)
end

function OilFileEx:reload_if_dir_changed()
  if self:oil_should_reload() then
    self:reload()
  else
    print "not reloading oil"
  end
end

function OilFileEx:new()
  self.__index = self
  return setmetatable({}, self)
end

function OilFileEx:down()
  if self.oil_bufnr and vim.api.nvim_buf_is_valid(self.oil_bufnr) then
    vim.api.nvim_buf_delete(self.oil_bufnr, { force = true })
    print "deleted buffer"
  else
    print "could not delete oil buffer"
  end

  if self.oil_winnr and vim.api.nvim_win_is_valid(self.oil_winnr) then
    vim.api.nvim_win_close(self.oil_winnr, true)
  end
end

function OilFileEx:kill()
  self:down()
  self.killed = true
end

return OilFileEx
