require('gitsigns').setup({
  on_attach = function(bufnr)
    local gitsigns = require('gitsigns')

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    map('n', ']c', function()
      if vim.wo.diff then
        vim.cmd.normal({ ']c', bang = true })
      else
        gitsigns.nav_hunk('next')
      end
    end, { desc = 'Next git hunk' })

    map('n', '[c', function()
      if vim.wo.diff then
        vim.cmd.normal({ '[c', bang = true })
      else
        gitsigns.nav_hunk('prev')
      end
    end, { desc = 'Prev git hunk' })

    map('n', '<leader>s', gitsigns.stage_buffer, { desc = 'Stage buffer' })
    map('n', '<leader>gs', gitsigns.stage_hunk, { desc = 'Stage hunk' })
    map('v', '<leader>gs', function()
      gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
    end, { desc = 'Stage selected lines' })
    map('n', '<leader>gr', gitsigns.reset_hunk, { desc = 'Reset hunk' })
    map('n', '<leader>gp', gitsigns.preview_hunk, { desc = 'Preview hunk diff' })
    map('n', '<leader>gb', function() gitsigns.blame_line({ full = true }) end, { desc = 'Blame line' })
    map('n', '<leader>gd', gitsigns.diffthis, { desc = 'Diff against index' })
  end,
})
