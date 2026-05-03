return {
  {
    'tpope/vim-fugitive',
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

        -- DoOnBufferClose(function()
        --   vim.cmd("G push")
        -- end, 5000)
      end)

      -- Diff viewing keymaps
      vim.keymap.set('n', '[c', '[czz')
      vim.keymap.set('n', ']c', ']czz')

      -- Whenever we are going between files with [q and and ]q we want to detect buffer changes
      -- but we only want to do this when difftool has populated the qf list
      -- TODO fix this shit
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
        local wins = vim.api.nvim_tabpage_list_wins(0)
        for _, win in ipairs(wins) do
          if vim.fn.win_gettype(win) == 'quickfix' then
            return true
          end
        end
        return false
      end

      local function diff_toggle_off()
        vim.cmd 'diffoff!'
        vim.cmd 'only'
        close_fugitive_diffs()
        if pre_diff_bufnr then
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

      vim.keymap.set('n', '<leader>df', function()
        if is_qf_open() then
          diff_toggle_off()
        else
          diff_toggle_on()
          vim.cmd 'G difftool'
        end
      end)

      -- diff something specific
      vim.keymap.set('n', '<leader>dF', function()
        if is_qf_open() then
          diff_toggle_off()
        else
          diff_toggle_on()
          vim.api.nvim_feedkeys(':G difftool ', 'n', false)
        end
      end)
    end,
  },
  {
    'justinmk/vim-ug',
    config = function()
      -- override this keymap for alternating between files
      vim.keymap.set('n', '<c-p>', '<c-^>', { noremap = false, silent = true })
      local push = function()
        vim.cmd 'G push --no-verify'
      end
      vim.keymap.set('n', 'Up', push, { noremap = false, silent = true })
      vim.keymap.set('n', 'UP', push, { noremap = false, silent = true })
    end,
  },
}
