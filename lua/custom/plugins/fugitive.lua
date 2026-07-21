return {
  {
    'tpope/vim-fugitive',
    dependencies = {
      'justinmk/vim-ug',
    },
    config = function(_)
      -- Use navigating merge conflict defaults for now [c for previous ]c for next conflict
      -- Set keybindings for resolving merge conflicts
      vim.keymap.set('n', '<leader>(', ':diffget //2<CR>')
      vim.keymap.set('n', '<leader>)', ':diffget //3<CR>')

      local function fugitive_commit()
        DoOnNewBuffer(function()
          -- Only set the lines if a new buffer is made within 2 seconds
          vim.api.nvim_buf_set_lines(0, 0, 1, true, { 'feat: ' })
        end, 2000)
        vim.cmd 'G commit -a --no-verify'
      end
      vim.keymap.set('n', '<leader>co', fugitive_commit)

      vim.keymap.set('n', '<leader>cp', function()
        fugitive_commit()

        vim.api.nvim_create_autocmd('BufWinLeave', {
          pattern = 'COMMIT_EDITMSG',
          callback = function()
            vim.schedule(function()
              vim.cmd 'G push'
            end)
          end,
          once = true,
        })
      end)

      -- Diff viewing keymaps
      vim.keymap.set('n', '[c', '[czz')
      vim.keymap.set('n', ']c', ']czz')

      -- Whenever we are going between files with [q and and ]q we want to detect buffer changes
      -- but we only want to do this when difftool has populated the qf list
      local difftool_var = 'difftool'

      local diffsplit_cmd = 'Gvdiffsplit!'

      local function is_difftool_qf()
        local qfbufnr = vim.fn.getqflist({ qfbufnr = 0 }).qfbufnr
        if qfbufnr == 0 then
          return false
        end
        local ok, val = pcall(vim.api.nvim_buf_get_var, qfbufnr, difftool_var)
        return ok and val == true
      end

      local function close_fugitive_diffs()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_get_name(buf):match '^fugitive://' then
            vim.api.nvim_buf_delete(buf, { force = true })
          end
        end
      end

      local function qf_navigate(dir)
        local qf = vim.fn.getqflist { idx = 0, size = 0 }
        if dir == 'next' and qf.idx >= qf.size then
          return
        end
        if dir == 'prev' and qf.idx <= 1 then
          return
        end
        local prev_buf = vim.api.nvim_get_current_buf()
        vim.cmd(dir == 'next' and 'cnext' or 'cprev')
        if is_difftool_qf() and vim.api.nvim_get_current_buf() ~= prev_buf then
          close_fugitive_diffs()
          vim.cmd(diffsplit_cmd)
        end
      end

      vim.keymap.set('n', '[q', function()
        qf_navigate 'prev'
      end)
      vim.keymap.set('n', ']q', function()
        qf_navigate 'next'
      end)

      local pre_diff_bufnr = nil
      local is_qf_open = function()
        for _, tp in ipairs(vim.api.nvim_list_tabpages()) do
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tp)) do
            if vim.fn.win_gettype(win) == 'quickfix' then
              return true
            end
          end
        end
        return false
      end

      local function diff_toggle_off()
        local diff_tabpage = nil
        for _, tp in ipairs(vim.api.nvim_list_tabpages()) do
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tp)) do
            if vim.fn.win_gettype(win) == 'quickfix' then
              diff_tabpage = tp
              break
            end
          end
          if diff_tabpage then
            break
          end
        end

        if diff_tabpage then
          vim.api.nvim_set_current_tabpage(diff_tabpage)
          vim.cmd 'diffoff!'
          close_fugitive_diffs()
          vim.cmd 'tabclose'
        else
          vim.cmd 'diffoff!'
          close_fugitive_diffs()
          vim.cmd 'only'
        end
        if pre_diff_bufnr and vim.api.nvim_buf_is_valid(pre_diff_bufnr) then
          vim.api.nvim_set_current_buf(pre_diff_bufnr)
          pre_diff_bufnr = nil
          local qfbufnr = vim.fn.getqflist({ qfbufnr = 0 }).qfbufnr
          pcall(vim.api.nvim_buf_del_var, qfbufnr, difftool_var)
        end
      end

      local function diff_toggle_on()
        pre_diff_bufnr = vim.api.nvim_get_current_buf()
        vim.api.nvim_create_autocmd('BufWinEnter', {
          callback = function(e)
            if vim.bo[e.buf].buftype == 'quickfix' then
              vim.api.nvim_buf_set_var(e.buf, difftool_var, true)
              vim.schedule(function()
                vim.cmd(diffsplit_cmd)
              end)
            end
          end,
          once = true,
        })
      end

      vim.keymap.set('n', 'Uf', function()
        if is_qf_open() then
          diff_toggle_off()
        else
          diff_toggle_on()
          vim.cmd 'tab split'
          vim.cmd 'G difftool'
        end
      end)

      -- diff something specific
      vim.keymap.set('n', 'UF', function()
        if is_qf_open() then
          diff_toggle_off()
        else
          diff_toggle_on()
          vim.cmd 'tab split'
          vim.api.nvim_feedkeys(':G difftool ', 'n', false)
        end
      end)

      -- merge tool - resolve merge conflicts via quickfix + diffsplit in a new tab
      vim.keymap.set('n', 'Um', function()
        if is_qf_open() then
          diff_toggle_off()
        else
          diff_toggle_on()
          vim.cmd 'tab split'
          vim.cmd 'G mergetool'
        end
      end)

      -- git log
      vim.keymap.set('n', 'Ul', function()
        vim.cmd 'G log'
      end)

      -- git log --oneline
      vim.keymap.set('n', '1Ul', function()
        vim.cmd 'G log --oneline'
      end)

      -- git log for current file
      vim.keymap.set('n', 'UL', function()
        vim.cmd 'G log %'
      end)
    end,
  },
  {
    'justinmk/vim-ug',
    config = function()
      -- keymap overrides
      vim.keymap.set('n', '<c-p>', '<c-^>', { noremap = false, silent = true })
      local push = function()
        vim.cmd 'G push --no-verify'
      end

      local pull = function()
        vim.cmd 'G pull'
      end

      vim.keymap.set('n', 'Up', push, { noremap = false, silent = true })
      vim.keymap.set('n', 'UP', pull, { noremap = false, silent = true })
    end,
  },
}
