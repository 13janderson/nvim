local M = {}

local term_bufnr = nil

local function is_valid(bufnr)
  return bufnr
      and vim.api.nvim_buf_is_valid(bufnr)
      and vim.bo[bufnr].buftype == "terminal"
end

local function send(cmd)
  if is_valid(term_bufnr) then
    local wins = vim.fn.win_findbuf(term_bufnr)
    if #wins > 0 then
      vim.api.nvim_set_current_win(wins[1])
    else
      vim.api.nvim_set_current_buf(term_bufnr)
    end
    vim.cmd("startinsert")
    vim.fn.chansend(vim.bo[term_bufnr].channel, cmd .. "\n")
  else
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(bufnr)
    vim.fn.termopen(vim.o.shell, {
      on_exit = function()
        term_bufnr = nil
      end,
    })
    term_bufnr = bufnr
    vim.cmd("startinsert")
    vim.schedule(function()
      vim.fn.chansend(vim.bo[bufnr].channel, cmd .. "\n")
    end)
  end
end

local function spawn()
  send("claude-sandbox --new")
end

local function jump_to_last()
  send("claude-sandbox --existing")
end

local function pick()
  if is_valid(term_bufnr) then
    vim.api.nvim_buf_delete(term_bufnr, { force = true })
  end
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(bufnr)
  vim.fn.termopen("claude-sandbox list-sessions", {
    on_exit = function()
      term_bufnr = nil
    end,
  })
  term_bufnr = bufnr
  vim.cmd("startinsert")
end

vim.keymap.set("n", "<leader>B", jump_to_last, { desc = "Claude Sandbox: attach to existing session" })
vim.keymap.set("n", "<leader>b", spawn, { desc = "Claude Sandbox: new session" })
vim.keymap.set("n", "<leader>sb", pick, { desc = "Claude Sandbox: pick session" })

M.spawn = spawn
M.pick = pick
M.jump_to_last = jump_to_last

return M
