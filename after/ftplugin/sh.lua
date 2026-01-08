OPTS_LOCAL_SCOPE = {
  scope = 'local',
}

vim.fn.setreg('o', 'yiwoechoa ""hpa: $p_')
vim.fn.setreg('p', 'yiw}iechoa ""hpa: $p_')
vim.api.nvim_set_option_value('makeprg', 'bash %', OPTS_LOCAL_SCOPE)

-- local Path = require 'plenary.path'
-- local full_buffer_path = Path:new(vim.fn.expand '%:p')
--
-- local on_exit = function(obj)
--   local err = obj.stderr
--   if obj.code == 0 and (err == '' or err == nil) then
--     local git_repo = vim.trim(obj.stdout)
--     print('repo', git_repo)
--     print('path', full_buffer_path)
--     local rel = full_buffer_path:make_relative(git_repo)
--     print('rel', rel)
--   else
--     print('Error', obj.stderr)
--     -- print(obj.stderr)
--   end
-- end
--
-- vim.system({ 'git', 'rev-parse', '--show-toplevel' }, on_exit)
