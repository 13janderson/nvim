-- Poor mans use of oil.nvim as a filetree

---@class OilFileTree
local OilFiletree = {}

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

local function open_oil_parent_dir()
  local dir = get_current_parent_dir()
  require "oil".open(dir)
end

-- Opens the filetree to the left of the current window
-- and sets up an autocmd for
function OilFiletree:up()
  self.code_winnr = vim.api.nvim_get_current_win()
  self.code_bufnr = vim.api.nvim_get_current_buf()

  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("OilFileTreeCodeWindow", { clear = true }),
    callback = function(_)
      if not vim.api.nvim_win_is_valid(self.code_winnr) or self.killed then
        return
      end

      local bufnr = vim.api.nvim_win_get_buf(self.code_winnr)
      if bufnr ~= self.code_bufnr then
        self.code_bufnr = bufnr
        self:reload()
      end
    end
  })
  self:load()
end

function OilFiletree:load()
  print "reloading"
  vim.cmd("40vs")
  open_oil_parent_dir()
  self.oil_bufnr = vim.api.nvim_get_current_buf()
  print("oil_bufnr", self.oil_bufnr)
  self.oil_winnr = vim.api.nvim_get_current_win()
  print("oil_winnr", self.oil_winnr)

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
          self:reload()
          -- put whatever was loaded into the code window
          vim.api.nvim_win_set_buf(self.code_winnr, bufnr)
        end
      end
    end
  })

  -- set focus back on self.winnr
  vim.api.nvim_set_current_win(self.code_winnr)
end

function OilFiletree:reload()
  vim.schedule(function()
    self:down()
    self:load()
  end)
end

function OilFiletree:new()
  self.__index = self
  return setmetatable({}, self)
end

function OilFiletree:down()
  if self.oil_bufnr and vim.api.nvim_buf_is_valid(self.oil_bufnr) then
    vim.api.nvim_buf_delete(self.oil_bufnr, { force = true })
  end

  if self.oil_winnr and vim.api.nvim_win_is_valid(self.oil_winnr) then
    vim.api.nvim_win_close(self.oil_winnr, true)
  end
end

function OilFiletree:kill()
  self:down()
  self.killed = true
end

return OilFiletree
